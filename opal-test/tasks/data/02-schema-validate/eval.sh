#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task: data-02-schema-validate ==="

# Criterion: Existing tests still pass
echo "--- Checking existing tests pass ---"
python3 -m pytest tests/ -q

# Run validation checks against all acceptance criteria
echo "--- Running validation checks ---"
python3 -c "
import sys, json
sys.path.insert(0, '.')
from ingest.pipeline import ingest
from ingest.schema import validate_record

with open('data/sample_records.json') as f:
    records = json.load(f)

result = ingest(records)

# Criterion: records 1 (Alice) and 6 (Frank) accepted, rest rejected
assert len(result['accepted']) == 2, f'Expected 2 accepted, got {len(result[\"accepted\"])}'
assert len(result['rejected']) == 6, f'Expected 6 rejected, got {len(result[\"rejected\"])}'
print('PASS: correct accepted/rejected counts (2/6)')

# Verify Alice and Frank are the accepted ones
accepted_names = [r['name'] for r in result['accepted']]
assert 'Alice' in accepted_names, 'Alice should be accepted'
assert 'Frank' in accepted_names, 'Frank should be accepted'
print('PASS: Alice and Frank accepted')

# Criterion: validate_record returns errors for empty name
errors = validate_record({'name': '', 'email': 'x@y.com', 'age': 25, 'role': 'user'})
assert len(errors) > 0, 'Empty name should produce errors'
print('PASS: empty name rejected')

# Criterion: validate_record returns errors for missing name
errors = validate_record({'email': 'x@y.com', 'age': 25, 'role': 'user'})
assert len(errors) > 0, 'Missing name should produce errors'
print('PASS: missing name rejected')

# Criterion: validate_record returns errors for invalid email (no @)
errors = validate_record({'name': 'Test', 'email': 'not-an-email', 'age': 25, 'role': 'user'})
assert len(errors) > 0, 'Invalid email should produce errors'
print('PASS: invalid email rejected')

# Criterion: validate_record returns errors for age < 0
errors = validate_record({'name': 'Test', 'email': 'x@y.com', 'age': -5, 'role': 'user'})
assert len(errors) > 0, 'Negative age should produce errors'
print('PASS: negative age rejected')

# Criterion: validate_record returns errors for age > 120
errors = validate_record({'name': 'Test', 'email': 'x@y.com', 'age': 150, 'role': 'user'})
assert len(errors) > 0, 'Age > 120 should produce errors'
print('PASS: age > 120 rejected')

# Criterion: validate_record returns errors for invalid role
errors = validate_record({'name': 'Test', 'email': 'x@y.com', 'age': 25, 'role': 'superadmin'})
assert len(errors) > 0, 'Invalid role should produce errors'
print('PASS: invalid role rejected')

# Criterion: valid roles are admin, user, editor
for role in ['admin', 'user', 'editor']:
    errors = validate_record({'name': 'Test', 'email': 'x@y.com', 'age': 25, 'role': role})
    assert len(errors) == 0, f'Role \"{role}\" should be valid but got errors: {errors}'
print('PASS: admin, user, editor are valid roles')

# Criterion (easy-to-miss): record 8 (Hank) missing email entirely - must not crash
errors = validate_record({'name': 'Hank', 'age': 40, 'role': 'admin'})
assert len(errors) > 0, 'Missing email field should produce errors'
has_email_error = any('email' in e.lower() or 'missing' in e.lower() for e in errors)
assert has_email_error, f'Error for missing email should mention email/missing: {errors}'
print('PASS: missing email field caught without crash')

# Criterion: each error message is descriptive (not just 'invalid')
all_rejected = result['rejected']
for entry in all_rejected:
    for err in entry['errors']:
        assert len(err) > 5, f'Error message too short/generic: \"{err}\"'
        assert err.lower() != 'invalid', f'Error message must be descriptive, not just \"invalid\"'
print('PASS: error messages are descriptive')

print()
print('ALL CHECKS PASSED')
"

echo "=== data-02-schema-validate: PASS ==="
