#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

# 1. Existing tests still pass
check "Existing tests pass" python3 -m pytest tests/test_v1.py -v

# 2. Accounts table has 4 rows
check "Accounts table has 4 rows" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
count = conn.execute('SELECT COUNT(*) FROM accounts').fetchone()[0]
assert count == 4, f'Expected 4 accounts, got {count}'
"

# 3. full_name is concatenated correctly
check "full_name is 'Alice Smith'" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT full_name FROM accounts WHERE id = 1').fetchone()
assert row is not None, 'Account 1 not found'
assert row['full_name'] == 'Alice Smith', f\"Expected 'Alice Smith', got '{row['full_name']}'\"
"

# 4. email comes from email_addr
check "email mapped from email_addr" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT email FROM accounts WHERE id = 1').fetchone()
assert row['email'] == 'alice@example.com', f\"Expected 'alice@example.com', got '{row['email']}'\"
"

# 5. created_at comes from signup_date
check "created_at mapped from signup_date" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT created_at FROM accounts WHERE id = 1').fetchone()
assert row['created_at'] == '2023-01-15', f\"Expected '2023-01-15', got '{row['created_at']}'\"
"

# 6. tier maps: free->basic, premium->premium
check "tier maps free to basic" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT tier FROM accounts WHERE id = 2').fetchone()
assert row['tier'] == 'basic', f\"Expected 'basic' for Bob (free user), got '{row['tier']}'\"
row2 = conn.execute('SELECT tier FROM accounts WHERE id = 1').fetchone()
assert row2['tier'] == 'premium', f\"Expected 'premium' for Alice, got '{row2['tier']}'\"
"

# 7. Transactions table has 6 rows
check "Transactions table has 6 rows" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
count = conn.execute('SELECT COUNT(*) FROM transactions').fetchone()[0]
assert count == 6, f'Expected 6 transactions, got {count}'
"

# 8. amount_dollars = price_cents / 100.0
check "amount_dollars conversion (4999 cents -> 49.99)" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT amount_dollars FROM transactions WHERE id = 1').fetchone()
assert row is not None, 'Transaction 1 not found'
assert abs(row['amount_dollars'] - 49.99) < 0.001, f\"Expected 49.99, got {row['amount_dollars']}\"
"

# 9. description comes from item_name
check "description mapped from item_name" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT description FROM transactions WHERE id = 1').fetchone()
assert row['description'] == 'Widget Pro', f\"Expected 'Widget Pro', got '{row['description']}'\"
"

# 10. Foreign key integrity
check "Foreign key integrity" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
orphans = conn.execute('''
    SELECT t.id FROM transactions t
    LEFT JOIN accounts a ON t.account_id = a.id
    WHERE a.id IS NULL
''').fetchall()
assert len(orphans) == 0, f'Found {len(orphans)} orphan transactions'
"

# 11. Carol is inactive (easy-to-miss: is_active=0 must be preserved)
check "Carol inactive status preserved (active=0)" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT active FROM accounts WHERE id = 3').fetchone()
assert row is not None, 'Account 3 (Carol) not found'
assert row['active'] == 0, f\"Expected active=0 for Carol, got {row['active']}\"
"

# 12. transaction_date comes from purchased_at
check "transaction_date mapped from purchased_at" python3 -c "
import sys, sqlite3; sys.path.insert(0, '.')
from db.v1_schema import create_v1
from db.v2_schema import create_v2_tables
from db.migrate import migrate_v1_to_v2
conn = sqlite3.connect(':memory:')
conn.row_factory = sqlite3.Row
create_v1(conn)
create_v2_tables(conn)
migrate_v1_to_v2(conn)
row = conn.execute('SELECT transaction_date FROM transactions WHERE id = 1').fetchone()
assert row['transaction_date'] == '2023-02-01T10:00:00', f\"Expected '2023-02-01T10:00:00', got '{row['transaction_date']}'\"
"

echo ""
echo "=== RESULTS ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
TOTAL=$((PASS + FAIL))
echo "TOTAL: $TOTAL"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
