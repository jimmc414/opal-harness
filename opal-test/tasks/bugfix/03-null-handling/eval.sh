#!/usr/bin/env bash
set -euo pipefail

cd "$WORK_DIR"

# Criterion 1: GET /users/<id> returns 200 for user with null email
python3 -c "
import sys
sys.path.insert(0, '.')
from app.routes import create_app
app = create_app()
client = app.test_client()

# User 3 has null email
resp = client.get('/users/3')
assert resp.status_code == 200, f'Expected 200, got {resp.status_code}'
data = resp.get_json()
assert data is not None, 'Response is not valid JSON'
assert 'email' in data, f'email field missing from response: {data}'
print('PASS: criterion 1 - GET /users/3 returns 200')
"

# Criterion 2: GET /users/ returns all users without error
python3 -c "
import sys
sys.path.insert(0, '.')
from app.routes import create_app
app = create_app()
client = app.test_client()

resp = client.get('/users/')
assert resp.status_code == 200, f'Expected 200, got {resp.status_code}'
data = resp.get_json()
assert isinstance(data, list), f'Expected list, got {type(data)}'
assert len(data) >= 4, f'Expected at least 4 users, got {len(data)}'
print('PASS: criterion 2 - GET /users/ returns all users')
"

# Criterion 3: All existing tests pass
python3 -m pytest tests/ -x -q

# Criterion 4: Null email must be JSON null, not empty string
python3 -c "
import json, sys
sys.path.insert(0, '.')
from app.routes import create_app
app = create_app()
client = app.test_client()

# Check single user endpoint
resp = client.get('/users/3')
data = resp.get_json()
assert data['email'] is None, (
    f'email for null-email user should be None/null, got {repr(data[\"email\"])}'
)
# Also verify it's not empty string in the raw JSON
raw = resp.get_data(as_text=True)
parsed = json.loads(raw)
assert parsed['email'] is None, (
    f'Raw JSON email should be null, got {repr(parsed[\"email\"])}'
)

# Check list endpoint
resp = client.get('/users/')
users = resp.get_json()
null_email_users = [u for u in users if u.get('email') is None]
assert len(null_email_users) >= 1, (
    'At least one user should have null email in list response'
)
# Verify none have empty-string email when they should be null
for u in users:
    if u.get('id') == 3:
        assert u['email'] is None, (
            f'User 3 email in list should be null, got {repr(u[\"email\"])}'
        )
print('PASS: criterion 4 - null email is JSON null, not empty string')
"

echo "ALL CRITERIA PASSED"
