#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task 05: Cursor-Based Pagination ==="

echo "--- Test 1: Existing tests pass ---"
python3 -m pytest tests/ -q --tb=short

echo "--- Test 2: Response has next_cursor key (not null on first page) ---"
python3 -c "
import sys, json
sys.path.insert(0, '.')
from app import create_app

app = create_app()
app.config['TESTING'] = True
client = app.test_client()

resp = client.get('/items')
assert resp.status_code == 200, f'Status {resp.status_code}'
data = resp.get_json()
assert 'next_cursor' in data, 'Response missing next_cursor key'
assert data['next_cursor'] is not None, 'First page next_cursor should not be null'
print('PASS: Response has non-null next_cursor on first page')
"

echo "--- Test 3: Response has items key with items ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app

app = create_app()
app.config['TESTING'] = True
client = app.test_client()

resp = client.get('/items')
data = resp.get_json()
assert 'items' in data, 'Response missing items key'
assert len(data['items']) > 0, 'Items list is empty'
print('PASS: Response has items key with items')
"

echo "--- Test 4: Cursor allows fetching next page ---"
python3 -c "
import sys, base64
sys.path.insert(0, '.')
from app import create_app

app = create_app()
app.config['TESTING'] = True
client = app.test_client()

resp = client.get('/items')
data = resp.get_json()
cursor = data['next_cursor']
decoded = base64.b64decode(cursor)
assert len(decoded) > 0, 'Cursor decoded to empty bytes'

resp2 = client.get(f'/items?cursor={cursor}')
assert resp2.status_code == 200, f'Cursor request failed: {resp2.status_code}'
data2 = resp2.get_json()
assert 'items' in data2, 'Cursor response missing items'
assert len(data2['items']) > 0, 'Cursor page has no items'

first_ids = {item['id'] for item in data['items']}
second_ids = {item['id'] for item in data2['items']}
assert first_ids.isdisjoint(second_ids), 'Pages have overlapping items'
print('PASS: Cursor fetches next page with different items')
"

echo "--- Test 5: Walk all pages, collect all 20 items ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app

app = create_app()
app.config['TESTING'] = True
client = app.test_client()

all_items = []
cursor = None
pages = 0
max_pages = 100

while pages < max_pages:
    url = '/items'
    if cursor:
        url = f'/items?cursor={cursor}'
    resp = client.get(url)
    assert resp.status_code == 200
    data = resp.get_json()
    assert 'items' in data
    all_items.extend(data['items'])
    cursor = data.get('next_cursor')
    pages += 1
    if cursor is None:
        break

assert pages < max_pages, 'Pagination did not terminate'
all_ids = [item['id'] for item in all_items]
assert len(all_ids) == 20, f'Expected 20 items, got {len(all_ids)}'
assert len(set(all_ids)) == 20, f'Duplicate items found'
assert set(all_ids) == set(range(1, 21)), 'Missing items'
print(f'PASS: All 20 items collected across {pages} pages, no duplicates')
"

echo "--- Test 6: per_page=5 returns 5 items with valid cursor ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app

app = create_app()
app.config['TESTING'] = True
client = app.test_client()

resp = client.get('/items?per_page=5')
assert resp.status_code == 200
data = resp.get_json()
assert len(data['items']) == 5, f'Expected 5 items, got {len(data[\"items\"])}'
assert data['next_cursor'] is not None, 'Expected non-null cursor with per_page=5'
print('PASS: per_page=5 returns 5 items with valid cursor')
"

echo "--- Test 7: Last page has next_cursor null ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app

app = create_app()
app.config['TESTING'] = True
client = app.test_client()

cursor = None
last_cursor = 'not_visited'
pages = 0

while pages < 100:
    url = '/items'
    if cursor:
        url = f'/items?cursor={cursor}'
    resp = client.get(url)
    data = resp.get_json()
    last_cursor = data.get('next_cursor')
    cursor = last_cursor
    pages += 1
    if cursor is None:
        break

assert last_cursor is None, f'Last page next_cursor should be null, got {last_cursor}'
print('PASS: Last page has next_cursor == null')
"

echo "=== All tests passed ==="
