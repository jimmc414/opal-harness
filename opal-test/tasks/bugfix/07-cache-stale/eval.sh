#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

echo "=== bugfix-07-cache-stale eval ==="

# Criterion 1: After update, get_product returns updated data
python -c "
from productservice.service import ProductService

svc = ProductService()

# Prime cache
p = svc.get_product('p1')
assert p['price'] == 19.99

# Update
svc.update_product('p1', {'price': 29.99})

# Must reflect update
p = svc.get_product('p1')
assert p['price'] == 29.99, f'Stale cache: expected 29.99, got {p[\"price\"]}'

print('PASS: update reflected in subsequent get')
"

# Criterion 2: Cache is properly invalidated or updated on writes
python -c "
from productservice.service import ProductService

svc = ProductService()

# Multiple sequential updates
svc.get_product('p2')
svc.update_product('p2', {'price': 59.99})
p = svc.get_product('p2')
assert p['price'] == 59.99, f'First update stale: {p[\"price\"]}'

svc.update_product('p2', {'price': 69.99, 'stock': 5})
p = svc.get_product('p2')
assert p['price'] == 69.99, f'Second update price stale: {p[\"price\"]}'
assert p['stock'] == 5, f'Second update stock stale: {p[\"stock\"]}'

print('PASS: cache properly updated/invalidated on writes')
"

# Criterion 3: All existing tests pass
python -m pytest tests/ -v --tb=short

# Criterion 4: list_products reflects updates immediately
python -c "
from productservice.service import ProductService

svc = ProductService()
svc.get_product('p1')
svc.update_product('p1', {'price': 99.99})

products = svc.list_products()
p1 = next(p for p in products if p['id'] == 'p1')
assert p1['price'] == 99.99, (
    f'list_products stale after update: {p1[\"price\"]}'
)

# Also verify list returns all products
assert len(products) == 3

print('PASS: list_products reflects updates immediately')
"

echo ""
echo "=== ALL CRITERIA PASSED ==="
