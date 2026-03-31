#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

run_test() {
    local name="$1"
    shift
    if "$@"; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

# Test 1: Existing tests still pass (they may need updating by the agent)
run_test "existing_tests_pass" python -c "
import subprocess, sys
result = subprocess.run([sys.executable, '-m', 'pytest', 'tests/test_items.py', '-x', '-q'],
                        capture_output=True, text=True)
sys.exit(0 if result.returncode == 0 else 1)
"

# Test 2: Request without token returns 401
run_test "no_token_returns_401" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    resp = c.get('/items')
    assert resp.status_code == 401, f'Expected 401 got {resp.status_code}'
"

# Test 3: Invalid token returns 401
run_test "invalid_token_returns_401" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    headers = {'Authorization': 'Bearer totally-fake-token'}
    resp = c.get('/items', headers=headers)
    assert resp.status_code == 401, f'Expected 401 got {resp.status_code}'
"

# Test 4: Viewer can GET /items
run_test "viewer_can_get_items" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    headers = {'Authorization': 'Bearer token-viewer-1'}
    resp = c.get('/items', headers=headers)
    assert resp.status_code == 200, f'Expected 200 got {resp.status_code}'
"

# Test 5: Viewer can GET /items/<id>
run_test "viewer_can_get_single_item" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    admin_h = {'Authorization': 'Bearer token-admin-1'}
    c.post('/items', json={'name': 'Widget', 'price': 9.99}, headers=admin_h)
    viewer_h = {'Authorization': 'Bearer token-viewer-1'}
    resp = c.get('/items/1', headers=viewer_h)
    assert resp.status_code == 200, f'Expected 200 got {resp.status_code}'
"

# Test 6: Viewer cannot POST /items
run_test "viewer_cannot_post" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    headers = {'Authorization': 'Bearer token-viewer-1'}
    resp = c.post('/items', json={'name': 'Gadget', 'price': 5.00}, headers=headers)
    assert resp.status_code == 403, f'Expected 403 got {resp.status_code}'
    data = resp.get_json()
    assert data.get('error') == 'forbidden', f'Expected error=forbidden got {data}'
"

# Test 7: Viewer cannot DELETE /items/<id>
run_test "viewer_cannot_delete" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    admin_h = {'Authorization': 'Bearer token-admin-1'}
    c.post('/items', json={'name': 'Widget', 'price': 9.99}, headers=admin_h)
    viewer_h = {'Authorization': 'Bearer token-viewer-1'}
    resp = c.delete('/items/1', headers=viewer_h)
    assert resp.status_code == 403, f'Expected 403 got {resp.status_code}'
    data = resp.get_json()
    assert data.get('error') == 'forbidden', f'Expected error=forbidden got {data}'
"

# Test 7b: Viewer cannot PUT /items/<id>
run_test "viewer_cannot_put" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    admin_h = {'Authorization': 'Bearer token-admin-1'}
    c.post('/items', json={'name': 'Widget', 'price': 9.99}, headers=admin_h)
    viewer_h = {'Authorization': 'Bearer token-viewer-1'}
    resp = c.put('/items/1', json={'name': 'Hacked'}, headers=viewer_h)
    assert resp.status_code == 403, f'Expected 403 got {resp.status_code}'
    data = resp.get_json()
    assert data.get('error') == 'forbidden', f'Expected error=forbidden got {data}'
"

# Test 8: Editor can POST /items
run_test "editor_can_post" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    headers = {'Authorization': 'Bearer token-editor-1'}
    resp = c.post('/items', json={'name': 'Gadget', 'price': 5.00}, headers=headers)
    assert resp.status_code == 201, f'Expected 201 got {resp.status_code}'
"

# Test 9: Editor can PUT /items/<id>
run_test "editor_can_put" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    headers = {'Authorization': 'Bearer token-editor-1'}
    c.post('/items', json={'name': 'Widget', 'price': 9.99}, headers=headers)
    resp = c.put('/items/1', json={'name': 'Super Widget'}, headers=headers)
    assert resp.status_code == 200, f'Expected 200 got {resp.status_code}'
"

# Test 10: Editor cannot DELETE
run_test "editor_cannot_delete" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    editor_h = {'Authorization': 'Bearer token-editor-1'}
    c.post('/items', json={'name': 'Widget', 'price': 9.99}, headers=editor_h)
    resp = c.delete('/items/1', headers=editor_h)
    assert resp.status_code == 403, f'Expected 403 got {resp.status_code}'
    data = resp.get_json()
    assert data.get('error') == 'forbidden', f'Expected error=forbidden got {data}'
"

# Test 11: Admin can DELETE
run_test "admin_can_delete" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    admin_h = {'Authorization': 'Bearer token-admin-1'}
    c.post('/items', json={'name': 'Widget', 'price': 9.99}, headers=admin_h)
    resp = c.delete('/items/1', headers=admin_h)
    assert resp.status_code == 200, f'Expected 200 got {resp.status_code}'
"

# Test 12: Admin can do all operations
run_test "admin_full_access" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    h = {'Authorization': 'Bearer token-admin-1'}
    r = c.get('/items', headers=h)
    assert r.status_code == 200, f'GET /items: expected 200 got {r.status_code}'
    r = c.post('/items', json={'name': 'A', 'price': 1.0}, headers=h)
    assert r.status_code == 201, f'POST /items: expected 201 got {r.status_code}'
    r = c.get('/items/1', headers=h)
    assert r.status_code == 200, f'GET /items/1: expected 200 got {r.status_code}'
    r = c.put('/items/1', json={'name': 'B'}, headers=h)
    assert r.status_code == 200, f'PUT /items/1: expected 200 got {r.status_code}'
    r = c.delete('/items/1', headers=h)
    assert r.status_code == 200, f'DELETE /items/1: expected 200 got {r.status_code}'
"

# Test 13: Editor can GET (all roles can read)
run_test "editor_can_get_items" python -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models
app = create_app()
app.config['TESTING'] = True
models.reset()
with app.test_client() as c:
    headers = {'Authorization': 'Bearer token-editor-1'}
    resp = c.get('/items', headers=headers)
    assert resp.status_code == 200, f'Expected 200 got {resp.status_code}'
"

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS + FAIL)) tests"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
