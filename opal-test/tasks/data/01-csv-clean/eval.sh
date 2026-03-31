#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task: data-01-csv-clean ==="

# Criterion: Existing tests still pass
echo "--- Checking existing tests pass ---"
python3 -m pytest tests/ -q

# Run the cleaning pipeline and validate all criteria
echo "--- Running validation checks ---"
python3 -c "
import sys, os, re
sys.path.insert(0, '.')
from cleaner.loader import load_csv
from cleaner.validator import clean_dataset

rows = load_csv('data/raw_sales.csv')
cleaned = clean_dataset(rows)

# Criterion: Rows with missing amount (row 3), non-numeric amount (row 5),
# missing customer (row 6), missing date (row 7) are skipped.
# Row 8 (missing region) should NOT be skipped.
# Remaining rows: 1, 2, 4, 8 = 4 rows
assert len(cleaned) == 4, f'Expected 4 clean rows, got {len(cleaned)}'
print('PASS: correct row count (4)')

# Criterion: amount values are converted to float
for row in cleaned:
    assert isinstance(row['amount'], float), f\"amount is {type(row['amount'])}, expected float\"
print('PASS: all amounts are float')

# Criterion: clean_dataset() normalizes all date formats to YYYY-MM-DD
date_re = re.compile(r'^\d{4}-\d{2}-\d{2}$')
for row in cleaned:
    assert date_re.match(row['date']), f\"Date '{row['date']}' not in YYYY-MM-DD format\"
print('PASS: all dates in YYYY-MM-DD format')

# Criterion: After cleaning, all remaining rows have non-empty customer names
for row in cleaned:
    assert row['customer'] and row['customer'].strip(), f\"Empty customer found\"
print('PASS: all customers non-empty')

# Verify specific date normalizations
dates = {row['id'] if isinstance(row['id'], str) else str(row['id']): row['date'] for row in cleaned}
# Row 1: already YYYY-MM-DD
assert dates.get('1') == '2024-01-15', f\"Row 1 date wrong: {dates.get('1')}\"
# Row 2: was 15/01/2024 -> 2024-01-15
assert dates.get('2') == '2024-01-15', f\"Row 2 date wrong: {dates.get('2')}\"
# Row 4: was Jan 20 2024 -> 2024-01-20
assert dates.get('4') == '2024-01-20', f\"Row 4 date wrong: {dates.get('4')}\"
print('PASS: specific date normalizations correct')

# Verify specific amounts
amounts = {row['id'] if isinstance(row['id'], str) else str(row['id']): row['amount'] for row in cleaned}
assert abs(amounts['1'] - 99.99) < 0.01
assert abs(amounts['2'] - 50.00) < 0.01
assert abs(amounts['4'] - 75.50) < 0.01
assert abs(amounts['8'] - 45.00) < 0.01
print('PASS: specific amounts correct')

# Criterion (easy-to-miss): Rows with missing region get region set to 'Unknown'
row8 = [r for r in cleaned if str(r.get('id')) == '8' or r.get('id') == '8']
assert len(row8) == 1, 'Row 8 (Hank) should be in cleaned output'
assert row8[0]['region'] == 'Unknown', f\"Row 8 region should be 'Unknown', got '{row8[0]['region']}'\"
print('PASS: missing region defaults to Unknown')

# Verify skipped rows are actually gone
ids = [str(r.get('id')) for r in cleaned]
assert '3' not in ids, 'Row 3 (missing amount) should be skipped'
assert '5' not in ids, 'Row 5 (non-numeric amount) should be skipped'
assert '6' not in ids, 'Row 6 (missing customer) should be skipped'
assert '7' not in ids, 'Row 7 (missing date) should be skipped'
print('PASS: correct rows skipped')

print()
print('ALL CHECKS PASSED')
"

echo "=== data-01-csv-clean: PASS ==="
