#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Test 1: Existing tests still pass ==="
python3 -m pytest tests/ -v --tb=short

echo "=== Test 2: GET /items?q=mouse returns exactly 2 items ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/items?q=mouse')
    assert r.status_code == 200, f'Expected 200, got {r.status_code}'
    data = r.get_json()
    assert len(data) == 2, f'Expected 2 items for q=mouse, got {len(data)}'
    names = sorted([d['name'] for d in data])
    assert names == ['Mouse Pad', 'Wireless Mouse'], f'Wrong items: {names}'
    print('PASS: q=mouse returns 2 items')
"

echo "=== Test 3: GET /items?q=KEYBOARD returns 1 item (case-insensitive) ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/items?q=KEYBOARD')
    assert r.status_code == 200, f'Expected 200, got {r.status_code}'
    data = r.get_json()
    assert len(data) == 1, f'Expected 1 item for q=KEYBOARD, got {len(data)}'
    assert data[0]['name'] == 'Mechanical Keyboard', f'Wrong item: {data[0][\"name\"]}'
    print('PASS: q=KEYBOARD returns 1 item (case-insensitive)')
"

echo "=== Test 4: GET /items?q=nonexistent returns 0 items ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/items?q=nonexistent')
    assert r.status_code == 200, f'Expected 200, got {r.status_code}'
    data = r.get_json()
    assert len(data) == 0, f'Expected 0 items for q=nonexistent, got {len(data)}'
    print('PASS: q=nonexistent returns 0 items')
"

echo "=== Test 5: GET /items (no param) returns all 5 items ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/items')
    assert r.status_code == 200, f'Expected 200, got {r.status_code}'
    data = r.get_json()
    assert len(data) == 5, f'Expected 5 items with no param, got {len(data)}'
    print('PASS: no param returns all 5 items')
"

echo "=== Test 6: GET /items?q= (empty) returns all 5 items ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/items?q=')
    assert r.status_code == 200, f'Expected 200, got {r.status_code}'
    data = r.get_json()
    assert len(data) == 5, f'Expected 5 items with empty q, got {len(data)}'
    print('PASS: empty q returns all 5 items')
"

echo "ALL TESTS PASSED"
