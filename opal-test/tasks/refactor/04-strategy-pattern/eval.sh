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

check_not() {
    local desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

# 1. All existing tests pass
check "All existing tests pass" python -m pytest tests/ -q --tb=short

# 2. send_notification callable with same interface
check "send_notification still importable" python -c "from notify.dispatcher import send_notification"

# 3. No if/elif chain on channel names in dispatcher.py
check_not "No elif channel == in dispatcher.py" grep -qE 'elif\s+channel\s*==' notify/dispatcher.py
check_not "No if channel == email in dispatcher.py" grep -qE "if\s+channel\s*==\s*['\"]email['\"]" notify/dispatcher.py

# 4. Each channel implemented as separate callable/class
check "Multiple channel handlers exist" python -c "
import ast, sys
with open('notify/dispatcher.py') as f:
    tree = ast.parse(f.read())
defs = [n for n in ast.walk(tree) if isinstance(n, (ast.FunctionDef, ast.ClassDef)) and n.name != 'send_notification']
assert len(defs) >= 5, f'Expected at least 5 handler definitions, found {len(defs)}'
"

# 5. Email works correctly
check "Email with subject" python -c "
from notify.dispatcher import send_notification
r = send_notification('email', 'user@test.com', 'Hello', subject='Test')
assert r == {'channel': 'email', 'to': 'user@test.com', 'subject': 'Test', 'body': 'Hello', 'status': 'sent'}
"

check "Email default subject" python -c "
from notify.dispatcher import send_notification
r = send_notification('email', 'user@test.com', 'Hello')
assert r['subject'] == 'Notification'
"

# 6. SMS truncation works
check "SMS truncation" python -c "
from notify.dispatcher import send_notification
r = send_notification('sms', '+1234567890', 'x' * 200)
assert len(r['body']) <= 160
assert r['body'].endswith('...')
"

# 7. Push default title
check "Push default title" python -c "
from notify.dispatcher import send_notification
r = send_notification('push', 'device-123', 'Alert!')
assert r['title'] == 'Alert'
"

# 8. Slack default channel
check "Slack default channel" python -c "
from notify.dispatcher import send_notification
r = send_notification('slack', 'user', 'Message')
assert r['slack_channel'] == '#general'
"

# 9. Webhook missing-url error case still works
check "Webhook missing url error" python -c "
from notify.dispatcher import send_notification
r = send_notification('webhook', 'service', 'Data')
assert r == {'channel': 'webhook', 'status': 'error', 'reason': 'missing url'}
"

# 10. Webhook with url works
check "Webhook with url" python -c "
from notify.dispatcher import send_notification
r = send_notification('webhook', 'service', 'Data', url='http://example.com/hook')
assert r['channel'] == 'webhook'
assert r['url'] == 'http://example.com/hook'
assert r['status'] == 'sent'
"

# 11. Unknown channel still returns error
check "Unknown channel error" python -c "
from notify.dispatcher import send_notification
r = send_notification('pigeon', 'bird', 'Coo')
assert r == {'channel': 'pigeon', 'status': 'error', 'reason': 'unknown channel'}
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
