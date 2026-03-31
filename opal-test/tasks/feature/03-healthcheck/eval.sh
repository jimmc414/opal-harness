#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Test 1: Existing tests still pass ==="
python3 -m pytest tests/ -v --tb=short

echo "=== Test 2: GET /health returns 200 ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/health')
    assert r.status_code == 200, f'Expected 200, got {r.status_code}'
    print('PASS: /health returns 200')
"

echo "=== Test 3: Response body is {\"status\": \"healthy\"} ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/health')
    data = r.get_json()
    assert data == {'status': 'healthy'}, f'Expected {{\"status\": \"healthy\"}}, got {data}'
    print('PASS: response body is correct')
"

echo "=== Test 4: Content-Type is application/json ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/health')
    ct = r.content_type
    assert 'application/json' in ct, f'Expected application/json, got {ct}'
    print('PASS: Content-Type is application/json')
"

echo "=== Test 5: Existing /items still works ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/items')
    assert r.status_code == 200, f'Expected 200, got {r.status_code}'
    data = r.get_json()
    assert len(data) == 3, f'Expected 3 items, got {len(data)}'
    print('PASS: /items still works')
"

echo "=== Test 6: POST /health returns 405 ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.post('/health')
    assert r.status_code == 405, f'POST /health should be 405, got {r.status_code}'
    print('PASS: POST /health returns 405')
"

echo "ALL TESTS PASSED"
