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
check "Existing tests pass" python3 -m pytest tests/test_etl.py -v

# 2. Coercion: string numbers are converted, not dropped
check "String numbers coerced (record 2 loaded)" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert 2 in by_id, 'Record 2 was dropped instead of coerced'
"

# 3. Record 2 price coerced from string to float
check "Record 2 price coerced to float 24.99" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert isinstance(by_id[2]['price'], float), f\"price is {type(by_id[2]['price'])}\"
assert abs(by_id[2]['price'] - 24.99) < 0.01
"

# 4. Record 2 quantity coerced from string to int
check "Record 2 quantity coerced to int 5" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert isinstance(by_id[2]['quantity'], int), f\"quantity is {type(by_id[2]['quantity'])}\"
assert by_id[2]['quantity'] == 5
"

# 5. String booleans coerced (record 2 active='yes' -> True)
check "Record 2 active coerced from 'yes' to True" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert isinstance(by_id[2]['active'], bool), f\"active is {type(by_id[2]['active'])}\"
assert by_id[2]['active'] is True
"

# 6. Record 4 id coerced from string '4' to int 4 (easy-to-miss)
check "Record 4 id coerced from string '4' to int 4" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert 4 in by_id, 'Record 4 was dropped instead of coerced'
assert isinstance(by_id[4]['id'], int), f\"id is {type(by_id[4]['id'])}\"
assert by_id[4]['id'] == 4
"

# 7. Null price record rejected (record 5)
check "Record 5 (null price) rejected" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert 5 not in by_id, 'Record 5 (null price) should be rejected'
"

# 8. Unconvertible record rejected (record 6: quantity='twelve')
check "Record 6 (unconvertible quantity) rejected" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert 6 not in by_id, 'Record 6 (twelve) should be rejected'
"

# 9. Empty name record rejected (record 7)
check "Record 7 (empty name) rejected" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert 7 not in by_id, 'Record 7 (empty name) should be rejected'
"

# 10. Negative quantity record rejected (record 8)
check "Record 8 (negative quantity) rejected" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
result = transform(extract('data/source.json'))
transformed = result[0] if isinstance(result, tuple) else result
by_id = {r['id']: r for r in transformed}
assert 8 not in by_id, 'Record 8 (negative quantity) should be rejected'
"

# 11. Exactly 4 records loaded, 4 rejected
check "Exactly 4 loaded and 4 rejected" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.extract import extract
from etl.transform import transform
from etl.load import TargetStore, load
result = transform(extract('data/source.json'))
if isinstance(result, tuple):
    transformed, errors = result
else:
    transformed = result
    errors = []
store = TargetStore()
load(store, transformed)
total_errors = len(errors) + len(store.get_errors())
assert len(store.get_all()) == 4, f'Expected 4 loaded, got {len(store.get_all())}'
assert total_errors == 4, f'Expected 4 rejected, got {total_errors}'
"

# 12. Error tracking mechanism exists (transform returns tuple or errors tracked)
check "Error tracking exists" python3 -c "
import sys; sys.path.insert(0, '.')
from etl.transform import transform
records = [
    {'id': 5, 'name': 'Test', 'price': None, 'quantity': 0, 'active': True},
    {'id': 1, 'name': 'Good', 'price': 9.99, 'quantity': 1, 'active': True},
]
result = transform(records)
if isinstance(result, tuple):
    transformed, errors = result
    assert len(errors) >= 1, 'Expected at least 1 error'
    assert len(transformed) == 1, 'Expected 1 valid record'
else:
    assert len(result) == 1, 'Null price should not be in output'
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
