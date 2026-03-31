#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task 07: Audit Logging ==="

echo "--- Test 1: Existing tests pass ---"
python3 -m pytest tests/ -q --tb=short

echo "--- Test 2: GET /audit-log returns 200 with empty list initially ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

resp = client.get('/audit-log')
assert resp.status_code == 200, f'Expected 200, got {resp.status_code}'
data = resp.get_json()
assert isinstance(data, list), 'Expected a list'
assert len(data) == 0, f'Expected empty list, got {len(data)} entries'
print('PASS: GET /audit-log returns empty list initially')
"

echo "--- Test 3: POST /items creates audit entry with action=create ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/items', json={'name': 'Widget', 'price': 9.99})

resp = client.get('/audit-log')
data = resp.get_json()
assert len(data) == 1, f'Expected 1 entry, got {len(data)}'
assert data[0]['action'] == 'create', f'Expected action=create, got {data[0][\"action\"]}'
print('PASS: POST /items creates audit entry with action=create')
"

echo "--- Test 4: PUT /items/<id> creates audit entry with action=update ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/items', json={'name': 'Widget', 'price': 9.99})
client.put('/items/1', json={'name': 'Super Widget'})

resp = client.get('/audit-log')
data = resp.get_json()
assert len(data) == 2, f'Expected 2 entries, got {len(data)}'
assert data[1]['action'] == 'update', f'Expected action=update, got {data[1][\"action\"]}'
print('PASS: PUT /items/<id> creates audit entry with action=update')
"

echo "--- Test 5: DELETE /items/<id> creates audit entry with action=delete ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/items', json={'name': 'Widget', 'price': 9.99})
client.delete('/items/1')

resp = client.get('/audit-log')
data = resp.get_json()
assert len(data) == 2, f'Expected 2 entries, got {len(data)}'
assert data[1]['action'] == 'delete', f'Expected action=delete, got {data[1][\"action\"]}'
print('PASS: DELETE /items/<id> creates audit entry with action=delete')
"

echo "--- Test 6: Audit entries have required fields ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/items', json={'name': 'Widget', 'price': 9.99})

resp = client.get('/audit-log')
data = resp.get_json()
entry = data[0]

required = ['action', 'resource_type', 'resource_id', 'timestamp']
for field in required:
    assert field in entry, f'Missing field: {field}'

assert entry['action'] == 'create'
assert entry['resource_type'] is not None
assert entry['resource_id'] is not None
assert entry['timestamp'] is not None
from datetime import datetime
datetime.fromisoformat(entry['timestamp'])
print('PASS: Audit entries have all required fields')
"

echo "--- Test 7: Read operations do NOT create audit entries ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/items', json={'name': 'Widget', 'price': 9.99})

resp = client.get('/audit-log')
count_before = len(resp.get_json())

client.get('/items')
client.get('/items/1')

resp = client.get('/audit-log')
count_after = len(resp.get_json())

assert count_before == count_after, f'Read ops created audit entries: {count_before} -> {count_after}'
print('PASS: Read operations do NOT create audit entries')
"

echo "--- Test 8: Multiple operations create entries in order ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/items', json={'name': 'A', 'price': 1.0})
client.post('/items', json={'name': 'B', 'price': 2.0})
client.put('/items/1', json={'name': 'A Updated'})
client.delete('/items/2')

resp = client.get('/audit-log')
data = resp.get_json()

assert len(data) == 4, f'Expected 4 entries, got {len(data)}'
assert data[0]['action'] == 'create'
assert data[1]['action'] == 'create'
assert data[2]['action'] == 'update'
assert data[3]['action'] == 'delete'
print('PASS: Multiple operations create entries in chronological order')
"

echo "=== All tests passed ==="
