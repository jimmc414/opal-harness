#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

echo "=== bugfix-08-regex-backtrack eval ==="

# Criterion 1: Valid emails still validate correctly
python -c "
from validators.email import validate_email

valid = [
    'user@example.com',
    'first.last@example.com',
    'user+tag@example.com',
    'user@my-domain.com',
    'user@mail.example.co.uk',
    'a@b.co',
]
for email in valid:
    assert validate_email(email) is True, f'Should be valid: {email}'

print('PASS: Valid emails accepted')
"

# Criterion 2: Invalid emails still rejected
python -c "
from validators.email import validate_email

invalid = [
    'userexample.com',
    'user@',
    '@example.com',
    '',
    'user@@example.com',
    'user@.com',
]
for email in invalid:
    assert validate_email(email) is False, f'Should be invalid: {email}'

print('PASS: Invalid emails rejected')
"

# Criterion 3: Adversarial input completes in under 2 seconds
python -c "
import signal
import sys

class Timeout(Exception):
    pass

def handler(signum, frame):
    raise Timeout()

from validators.email import validate_email

adversarial = 'a' * 30 + '@'
signal.signal(signal.SIGALRM, handler)
signal.alarm(2)
try:
    result = validate_email(adversarial)
    assert result is False, 'Adversarial input should be rejected'
except Timeout:
    print('FAIL: validate_email took >2s on adversarial input', file=sys.stderr)
    sys.exit(1)
finally:
    signal.alarm(0)

print('PASS: Adversarial input handled in <2 seconds')
"

# Criterion 4: All existing tests pass
python -m pytest tests/ -v --tb=short --timeout=10

# Criterion 5: Consecutive dots in domain are still rejected
python -c "
from validators.email import validate_email

# Consecutive dots in domain must be rejected
assert validate_email('user@foo..bar.com') is False, (
    'Consecutive dots in domain should be rejected'
)
assert validate_email('user@..example.com') is False, (
    'Leading consecutive dots in domain should be rejected'
)
# But single dots are fine
assert validate_email('user@foo.bar.com') is True, (
    'Single dots in domain should be accepted'
)

print('PASS: Consecutive dots in domain correctly rejected')
"

echo ""
echo "=== ALL CRITERIA PASSED ==="
