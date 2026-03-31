#!/usr/bin/env bash
set -euo pipefail

cd "$WORK_DIR"

# Criterion 1: parse_csv returns dicts with stripped header keys
python3 -c "
from csvlib.parser import parse_csv
rows = parse_csv('data/sample.csv')
assert len(rows) > 0, 'No rows returned'
for row in rows:
    for key in row.keys():
        assert key == key.strip(), f'Header not stripped: repr={repr(key)}'
# Verify expected clean keys exist
assert 'name' in rows[0], f'Key \"name\" not found. Keys: {list(rows[0].keys())}'
assert 'age' in rows[0], f'Key \"age\" not found. Keys: {list(rows[0].keys())}'
assert 'id' in rows[0], f'Key \"id\" not found. Keys: {list(rows[0].keys())}'
assert 'email' in rows[0], f'Key \"email\" not found. Keys: {list(rows[0].keys())}'
print('PASS: criterion 1 - stripped header keys')
"

# Criterion 2: All existing tests pass
python3 -m pytest tests/ -x -q

# Criterion 3: Handles tabs and mixed whitespace
python3 -c "
import tempfile, os
from csvlib.parser import parse_csv

# Create a CSV with tab/mixed whitespace headers
content = '\t name \t,\t\tage\t, email \n\tAlice\t,30,alice@test.com\n'
with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False, dir='.') as f:
    f.write(content)
    tmppath = f.name

try:
    rows = parse_csv(tmppath)
    assert len(rows) > 0, 'No rows returned from tab-whitespace CSV'
    for row in rows:
        for key in row.keys():
            assert key == key.strip(), f'Tab whitespace not stripped: repr={repr(key)}'
    assert 'name' in rows[0], f'Key \"name\" not found after tab strip. Keys: {list(rows[0].keys())}'
    assert 'age' in rows[0], f'Key \"age\" not found after tab strip. Keys: {list(rows[0].keys())}'
    assert 'email' in rows[0], f'Key \"email\" not found after tab strip. Keys: {list(rows[0].keys())}'
    print('PASS: criterion 3 - tab and mixed whitespace handled')
finally:
    os.unlink(tmppath)
"

# Criterion 4: Still works with clean.csv (no whitespace issues)
python3 -c "
from csvlib.parser import parse_csv
rows = parse_csv('data/clean.csv')
assert len(rows) > 0, 'No rows returned from clean.csv'
assert 'id' in rows[0], f'Key \"id\" not found in clean.csv. Keys: {list(rows[0].keys())}'
assert 'name' in rows[0], f'Key \"name\" not found in clean.csv. Keys: {list(rows[0].keys())}'
assert 'email' in rows[0], f'Key \"email\" not found in clean.csv. Keys: {list(rows[0].keys())}'
assert 'age' in rows[0], f'Key \"age\" not found in clean.csv. Keys: {list(rows[0].keys())}'
# Verify values are correct
assert rows[0]['name'] == 'Alice', f'Expected Alice, got {rows[0][\"name\"]}'
print('PASS: criterion 4 - clean.csv still works')
"

echo "ALL CRITERIA PASSED"
