#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task: data-03-normalize ==="

# Criterion: Existing tests still pass
echo "--- Checking existing tests pass ---"
python3 -m pytest tests/ -q

# Run normalization and verify all criteria
echo "--- Running normalization checks ---"
python3 -c "
import sys, sqlite3
sys.path.insert(0, '.')
from database.setup import create_db
from database.normalize import normalize

conn = create_db()
normalize(conn)

# Criterion: normalize(conn) creates customers table
try:
    rows = conn.execute('SELECT * FROM customers').fetchall()
except Exception as e:
    print(f'FAIL: customers table does not exist: {e}')
    sys.exit(1)
print('PASS: customers table exists')

# Criterion: customers has 4 unique entries
customer_count = conn.execute('SELECT COUNT(*) FROM customers').fetchone()[0]
assert customer_count == 4, f'Expected 4 customers, got {customer_count}'
print('PASS: 4 customers')

# Criterion: normalize(conn) creates products table
try:
    rows = conn.execute('SELECT * FROM products').fetchall()
except Exception as e:
    print(f'FAIL: products table does not exist: {e}')
    sys.exit(1)
print('PASS: products table exists')

# Criterion: products has 3 unique entries
product_count = conn.execute('SELECT COUNT(*) FROM products').fetchone()[0]
assert product_count == 3, f'Expected 3 products, got {product_count}'
print('PASS: 3 products')

# Criterion: normalized orders table exists with customer_id and product_id
# Check for a normalized orders table (could be named normalized_orders or orders could be modified)
norm_table = None
for table_name in ['normalized_orders', 'norm_orders', 'orders_normalized']:
    try:
        conn.execute(f'SELECT customer_id, product_id FROM {table_name}').fetchone()
        norm_table = table_name
        break
    except:
        pass

if norm_table is None:
    # Check if the original orders table has been augmented with customer_id/product_id
    try:
        conn.execute('SELECT customer_id, product_id FROM orders').fetchone()
        norm_table = 'orders'
    except:
        pass

if norm_table is None:
    print('FAIL: No normalized orders table found with customer_id and product_id columns')
    sys.exit(1)
print(f'PASS: normalized orders table found ({norm_table})')

# Criterion: All 7 original orders preserved
order_count = conn.execute(f'SELECT COUNT(*) FROM {norm_table}').fetchone()[0]
assert order_count == 7, f'Expected 7 normalized orders, got {order_count}'
print('PASS: all 7 orders preserved')

# Criterion: Normalized orders references customer_id and product_id
row = conn.execute(f'SELECT customer_id, product_id, quantity, order_date FROM {norm_table} LIMIT 1').fetchone()
assert row is not None, 'Normalized orders table is empty'
print('PASS: normalized orders have customer_id, product_id, quantity, order_date')

# Verify foreign key integrity: all customer_ids exist in customers
orphan_customers = conn.execute(f'''
    SELECT COUNT(*) FROM {norm_table} no
    WHERE no.customer_id NOT IN (SELECT id FROM customers)
''').fetchone()[0]
assert orphan_customers == 0, f'{orphan_customers} orders have invalid customer_id'
print('PASS: all customer_id references valid')

# Verify foreign key integrity: all product_ids exist in products
orphan_products = conn.execute(f'''
    SELECT COUNT(*) FROM {norm_table} no
    WHERE no.product_id NOT IN (SELECT id FROM products)
''').fetchone()[0]
assert orphan_products == 0, f'{orphan_products} orders have invalid product_id'
print('PASS: all product_id references valid')

# Criterion: Customer deduplication uses email as unique key
emails = conn.execute('SELECT email FROM customers').fetchall()
email_list = [r[0] for r in emails]
assert len(email_list) == len(set(email_list)), 'Customer emails are not unique'
assert 'alice@example.com' in email_list
assert 'bob@example.com' in email_list
assert 'carol@example.com' in email_list
assert 'dave@example.com' in email_list
print('PASS: customer deduplication by email correct')

# Criterion (easy-to-miss): Bob phone should be 555-0202 (non-null value)
bob = conn.execute(\"SELECT phone FROM customers WHERE email = 'bob@example.com'\").fetchone()
assert bob is not None, 'Bob not found in customers'
assert bob[0] == '555-0202', f\"Bob phone should be '555-0202', got '{bob[0]}'\"
print('PASS: Bob phone is 555-0202 (non-null preferred)')

# Verify customer names
names = [r[0] for r in conn.execute('SELECT name FROM customers').fetchall()]
assert 'Alice Smith' in names
assert 'Bob Jones' in names
assert 'Carol White' in names
assert 'Dave Brown' in names
print('PASS: all customer names correct')

# Verify product names
prod_names = [r[0] for r in conn.execute('SELECT name FROM products').fetchall()]
assert 'Widget' in prod_names
assert 'Gadget' in prod_names
assert 'Doohickey' in prod_names
print('PASS: all product names correct')

# Criterion: Original flat orders table still queryable (existing tests depend on it)
flat_count = conn.execute('SELECT COUNT(*) FROM orders WHERE customer_name IS NOT NULL').fetchone()[0]
assert flat_count == 7, f'Original flat orders table should still have 7 rows, got {flat_count}'
print('PASS: original flat orders table preserved')

print()
print('ALL CHECKS PASSED')
"

echo "=== data-03-normalize: PASS ==="
