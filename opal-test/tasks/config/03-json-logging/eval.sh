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

# Run existing app tests
check "Existing app tests pass" python3 -m pytest tests/ -q --tb=short

# Capture log output and verify JSON format
check "Log output is valid JSON" python3 -c "
import json
import logging
import io

# Reset logging to capture fresh output
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

from app import create_app
app = create_app()
app.config['TESTING'] = True

# Find the handler that writes to our logger
root_logger = logging.getLogger()
captured = io.StringIO()
for handler in root_logger.handlers:
    if hasattr(handler, 'stream'):
        handler.stream = captured

with app.test_client() as c:
    c.get('/api/items')

output = captured.getvalue()
assert output.strip(), 'No log output captured'
for line in output.strip().split('\n'):
    if line.strip():
        obj = json.loads(line)
        assert isinstance(obj, dict), 'Log line is not a JSON object'
"

# Verify required fields exist
check "Log entries have timestamp, level, message fields" python3 -c "
import json
import logging
import io

for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

from app import create_app
app = create_app()
app.config['TESTING'] = True

root_logger = logging.getLogger()
captured = io.StringIO()
for handler in root_logger.handlers:
    if hasattr(handler, 'stream'):
        handler.stream = captured

with app.test_client() as c:
    c.get('/api/items')

output = captured.getvalue()
for line in output.strip().split('\n'):
    if line.strip():
        obj = json.loads(line)
        assert 'timestamp' in obj, f'Missing timestamp field: {obj}'
        assert 'level' in obj, f'Missing level field: {obj}'
        assert 'message' in obj, f'Missing message field: {obj}'
"

# Verify level field uses standard names
check "Level field uses standard names (INFO, WARNING, ERROR)" python3 -c "
import json
import logging
import io

for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

from app import create_app
app = create_app()
app.config['TESTING'] = True

root_logger = logging.getLogger()
captured = io.StringIO()
for handler in root_logger.handlers:
    if hasattr(handler, 'stream'):
        handler.stream = captured

with app.test_client() as c:
    c.get('/api/items')

output = captured.getvalue()
valid_levels = {'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'}
for line in output.strip().split('\n'):
    if line.strip():
        obj = json.loads(line)
        assert obj['level'] in valid_levels, f'Invalid level: {obj[\"level\"]}'
"

# Verify ISO 8601 timestamp
check "Timestamp is ISO 8601 format" python3 -c "
import json
import logging
import io
from datetime import datetime

for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

from app import create_app
app = create_app()
app.config['TESTING'] = True

root_logger = logging.getLogger()
captured = io.StringIO()
for handler in root_logger.handlers:
    if hasattr(handler, 'stream'):
        handler.stream = captured

with app.test_client() as c:
    c.get('/api/items')

output = captured.getvalue()
for line in output.strip().split('\n'):
    if line.strip():
        obj = json.loads(line)
        ts = obj['timestamp']
        # Replace trailing Z with +00:00 for fromisoformat compatibility
        if ts.endswith('Z'):
            ts = ts[:-1] + '+00:00'
        datetime.fromisoformat(ts)
"

# Verify warning level logging works
check "Warning level logging produces valid JSON" python3 -c "
import json
import logging
import io

for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

from app import create_app
app = create_app()
app.config['TESTING'] = True

root_logger = logging.getLogger()
captured = io.StringIO()
for handler in root_logger.handlers:
    if hasattr(handler, 'stream'):
        handler.stream = captured

with app.test_client() as c:
    c.post('/api/items', json={})

output = captured.getvalue()
found_warning = False
for line in output.strip().split('\n'):
    if line.strip():
        obj = json.loads(line)
        if obj.get('level') == 'WARNING':
            found_warning = True
assert found_warning, 'No WARNING level log entry found'
"

# Easy-to-miss: special characters in log messages must not break JSON
check "JSON formatter handles special characters (quotes, newlines)" python3 -c "
import json
import logging
import io

for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

from app import create_app
app = create_app()
app.config['TESTING'] = True

root_logger = logging.getLogger()
captured = io.StringIO()
for handler in root_logger.handlers:
    if hasattr(handler, 'stream'):
        handler.stream = captured

logger = logging.getLogger('test.special')
logger.info('Message with \"quotes\" and a\nnewline')
logger.warning('Backslash: C:\\\\path\\\\to\\\\file')

output = captured.getvalue()
assert output.strip(), 'No log output for special character test'
for line in output.strip().split('\n'):
    if line.strip():
        obj = json.loads(line)
        assert 'message' in obj, 'Missing message field'
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
