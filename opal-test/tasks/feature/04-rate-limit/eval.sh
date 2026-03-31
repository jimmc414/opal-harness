#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Test 1: Existing tests still pass ==="
python3 -m pytest tests/ -v --tb=short

echo "=== Test 2: First 5 requests return 200 ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    for i in range(5):
        r = c.get('/items')
        assert r.status_code == 200, f'Request {i+1} failed: expected 200, got {r.status_code}'
    print('PASS: first 5 requests all return 200')
"

echo "=== Test 3: 6th request returns 429 ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    for i in range(5):
        r = c.get('/items')
        assert r.status_code == 200, f'Request {i+1} failed: expected 200, got {r.status_code}'
    r = c.get('/items')
    assert r.status_code == 429, f'6th request should be 429, got {r.status_code}'
    print('PASS: 6th request returns 429')
"

echo "=== Test 4: 429 response has correct error JSON ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    for i in range(5):
        c.get('/items')
    r = c.get('/items')
    assert r.status_code == 429
    data = r.get_json()
    assert data is not None, 'Response body is not JSON'
    assert 'error' in data, f'Missing error key in response: {data}'
    assert data['error'] == 'rate limit exceeded', f'Wrong error message: {data[\"error\"]}'
    print('PASS: 429 response has correct error JSON')
"

echo "=== Test 5: Fresh client first request is 200 ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    r = c.get('/items')
    assert r.status_code == 200, f'First request on fresh client should be 200, got {r.status_code}'
    data = r.get_json()
    assert len(data) == 3, f'Expected 3 items, got {len(data)}'
    print('PASS: fresh client first request is 200')
"

echo "=== Test 6: Per-IP independence ==="
python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    for i in range(5):
        r = c.get('/items', environ_base={'REMOTE_ADDR': '10.0.0.1'})
        assert r.status_code == 200, f'IP1 request {i+1} failed: {r.status_code}'
    r = c.get('/items', environ_base={'REMOTE_ADDR': '10.0.0.2'})
    assert r.status_code == 200, f'Different IP should get 200, got {r.status_code}'
    print('PASS: per-IP independence verified')
"

echo "=== Test 7: Window expiry ==="
python3 -c "
from unittest.mock import patch
import time as _time
from app import create_app

app = create_app()
app.config['TESTING'] = True

fake_time = [1000.0]

with patch('time.time', side_effect=lambda: fake_time[0]):
    with app.test_client() as c:
        for i in range(5):
            r = c.get('/items')
            assert r.status_code == 200, f'Request {i+1} failed: {r.status_code}'
        r = c.get('/items')
        assert r.status_code == 429, f'6th request should be 429, got {r.status_code}'
        fake_time[0] += 61.0
        r = c.get('/items')
        assert r.status_code == 200, f'After window expiry should be 200, got {r.status_code}'
        print('PASS: rate limit resets after time window')
"

echo "ALL TESTS PASSED"
