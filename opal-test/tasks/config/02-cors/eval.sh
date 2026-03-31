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

# Run existing API tests
check "Existing API tests pass" python3 -m pytest tests/ -q --tb=short

# Test CORS headers via Flask test client
check "GET /api/items has Access-Control-Allow-Origin header" python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    resp = c.get('/api/items', headers={'Origin': 'http://localhost:3000'})
    acao = resp.headers.get('Access-Control-Allow-Origin', '')
    assert acao == 'http://localhost:3000', f'Expected http://localhost:3000, got {acao!r}'
"

check "Allowed origin is http://localhost:3000 not wildcard" python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    resp = c.get('/api/items', headers={'Origin': 'http://localhost:3000'})
    acao = resp.headers.get('Access-Control-Allow-Origin', '')
    assert acao != '*', 'Origin must not be wildcard *'
    assert acao == 'http://localhost:3000', f'Expected http://localhost:3000, got {acao!r}'
"

check "OPTIONS /api/items returns 200 with CORS headers" python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    resp = c.options('/api/items', headers={
        'Origin': 'http://localhost:3000',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type',
    })
    assert resp.status_code == 200, f'Expected 200, got {resp.status_code}'
    acao = resp.headers.get('Access-Control-Allow-Origin', '')
    assert acao == 'http://localhost:3000', f'Preflight missing correct origin: {acao!r}'
"

check "Preflight includes Access-Control-Allow-Methods with GET and POST" python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    resp = c.options('/api/items', headers={
        'Origin': 'http://localhost:3000',
        'Access-Control-Request-Method': 'POST',
    })
    methods = resp.headers.get('Access-Control-Allow-Methods', '')
    assert 'GET' in methods, f'GET not in Allow-Methods: {methods!r}'
    assert 'POST' in methods, f'POST not in Allow-Methods: {methods!r}'
"

check "Preflight includes Access-Control-Allow-Headers with Content-Type" python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    resp = c.options('/api/items', headers={
        'Origin': 'http://localhost:3000',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type',
    })
    headers_val = resp.headers.get('Access-Control-Allow-Headers', '')
    assert 'Content-Type' in headers_val or 'content-type' in headers_val.lower(), \
        f'Content-Type not in Allow-Headers: {headers_val!r}'
"

# Easy-to-miss: CORS headers on actual POST response, not just preflight
check "POST /api/items actual response has CORS headers" python3 -c "
from app import create_app
app = create_app()
app.config['TESTING'] = True
with app.test_client() as c:
    resp = c.post('/api/items',
        json={'name': 'TestItem', 'price': 1.0},
        headers={'Origin': 'http://localhost:3000'})
    assert resp.status_code == 201, f'Expected 201, got {resp.status_code}'
    acao = resp.headers.get('Access-Control-Allow-Origin', '')
    assert acao == 'http://localhost:3000', \
        f'POST response missing CORS origin header: {acao!r}'
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
