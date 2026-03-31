#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

echo "=== bugfix-05-encoding-bom eval ==="

# Criterion 1 & 2: read_csv works on both regular and BOM files, headers identical
python -c "
from fileprocessor.reader import read_csv, get_headers

# Read both files
regular = read_csv('data/regular.csv')
bom = read_csv('data/bom.csv')

# Both should have 5 rows
assert len(regular) == 5, f'Regular CSV: expected 5 rows, got {len(regular)}'
assert len(bom) == 5, f'BOM CSV: expected 5 rows, got {len(bom)}'

# BOM file must have clean 'id' key (no \\ufeff prefix)
assert 'id' in bom[0], f'BOM first row keys: {list(bom[0].keys())}'
assert bom[0]['id'] == '1', f'BOM first id: {bom[0].get(\"id\", \"MISSING\")}'

# Headers must match between files
rh = get_headers('data/regular.csv')
bh = get_headers('data/bom.csv')
assert rh == bh, f'Headers differ: regular={rh}, bom={bh}'

# No header should contain BOM character
for h in bh:
    assert '\ufeff' not in h, f'Header contains BOM: {h!r}'

print('PASS: read_csv works on both file types, headers are clean')
"

# Criterion 3: All existing tests pass
python -m pytest tests/ -v --tb=short

# Criterion 4: Non-BOM files must still work correctly (utf-8-sig on non-BOM)
python -c "
from fileprocessor.reader import read_csv, get_headers

rows = read_csv('data/regular.csv')
assert len(rows) == 5
assert rows[0] == {'id': '1', 'name': 'Alice', 'value': '100'}
assert rows[4] == {'id': '5', 'name': 'Eve', 'value': '250'}

headers = get_headers('data/regular.csv')
assert headers == ['id', 'name', 'value'], f'Non-BOM headers corrupted: {headers}'

print('PASS: Non-BOM files unaffected by fix')
"

echo ""
echo "=== ALL CRITERIA PASSED ==="
