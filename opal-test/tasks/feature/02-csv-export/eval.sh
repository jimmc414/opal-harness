#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Test 1: Existing tests still pass ==="
python3 -m pytest tests/ -v --tb=short

echo "=== Test 2: format_csv is importable ==="
python3 -c "
from reports.formatters import format_csv
print('PASS: format_csv is importable')
"

echo "=== Test 3: format_csv returns header row matching columns ==="
python3 -c "
from reports.formatters import format_csv
from reports.models import Report
import csv
import io

report = Report(
    title='Sales Report',
    columns=['name', 'amount', 'region'],
    rows=[
        {'name': 'Alice', 'amount': 1500, 'region': 'North'},
        {'name': 'Bob', 'amount': 2300, 'region': 'South'},
    ]
)
result = format_csv(report)
reader = csv.reader(io.StringIO(result))
rows = list(reader)
assert rows[0] == ['name', 'amount', 'region'], f'Header mismatch: {rows[0]}'
print('PASS: header row matches columns')
"

echo "=== Test 4: Data rows present with correct values ==="
python3 -c "
from reports.formatters import format_csv
from reports.models import Report
import csv
import io

report = Report(
    title='Sales Report',
    columns=['name', 'amount', 'region'],
    rows=[
        {'name': 'Alice', 'amount': 1500, 'region': 'North'},
        {'name': 'Bob', 'amount': 2300, 'region': 'South'},
    ]
)
result = format_csv(report)
reader = csv.reader(io.StringIO(result))
rows = list(reader)
assert len(rows) == 3, f'Expected 3 rows (header + 2 data), got {len(rows)}'
assert rows[1][0] == 'Alice', f'Expected Alice, got {rows[1][0]}'
assert rows[1][1] == '1500', f'Expected 1500, got {rows[1][1]}'
assert rows[2][0] == 'Bob', f'Expected Bob, got {rows[2][0]}'
print('PASS: data rows have correct values')
"

echo "=== Test 5: Handles commas in data (proper quoting) ==="
python3 -c "
from reports.formatters import format_csv
from reports.models import Report
import csv
import io

report = Report(
    title='Test',
    columns=['name', 'description'],
    rows=[
        {'name': 'Item A', 'description': 'Contains, commas'},
    ]
)
result = format_csv(report)
reader = csv.reader(io.StringIO(result))
rows = list(reader)
assert rows[1][1] == 'Contains, commas', f'Comma handling failed: {rows[1][1]}'
print('PASS: commas in data handled correctly')
"

echo "=== Test 6: Handles quotes in data (proper escaping) ==="
python3 -c "
from reports.formatters import format_csv
from reports.models import Report
import csv
import io

report = Report(
    title='Test',
    columns=['name', 'value'],
    rows=[
        {'name': 'Item \"B\"', 'value': 200},
    ]
)
result = format_csv(report)
reader = csv.reader(io.StringIO(result))
rows = list(reader)
assert rows[1][0] == 'Item \"B\"', f'Quote handling failed: {rows[1][0]}'
print('PASS: quotes in data handled correctly')
"

echo "ALL TESTS PASSED"
