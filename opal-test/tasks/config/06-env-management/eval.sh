#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# --- AC: Config files exist ---
if [ -f "config/development.py" ]; then
    pass "config/development.py exists"
else
    fail "config/development.py missing"
fi

if [ -f "config/staging.py" ]; then
    pass "config/staging.py exists"
else
    fail "config/staging.py missing"
fi

if [ -f "config/production.py" ]; then
    pass "config/production.py exists"
else
    fail "config/production.py missing"
fi

# --- AC: create_app(env) loads correct config ---
# Development: DEBUG=True, LOG_LEVEL='DEBUG', sqlite database
python3 -c "
import sys, os
sys.path.insert(0, '.')
from app import create_app

app = create_app('development')
with app.app_context():
    assert app.config.get('DEBUG') is True, f\"dev DEBUG should be True, got {app.config.get('DEBUG')}\"
    assert app.config.get('LOG_LEVEL') == 'DEBUG', f\"dev LOG_LEVEL should be DEBUG, got {app.config.get('LOG_LEVEL')}\"
    db = app.config.get('DATABASE_URL', '')
    assert 'sqlite' in str(db).lower(), f\"dev should use sqlite, got {db}\"
print('development config OK')
" && pass "development config correct (DEBUG=True, LOG_LEVEL=DEBUG, sqlite)" || fail "development config incorrect"

# Staging: DEBUG=False, LOG_LEVEL='WARNING'
python3 -c "
import sys, os
sys.path.insert(0, '.')
from app import create_app

app = create_app('staging')
with app.app_context():
    assert app.config.get('DEBUG') is False, f\"staging DEBUG should be False, got {app.config.get('DEBUG')}\"
    assert app.config.get('LOG_LEVEL') == 'WARNING', f\"staging LOG_LEVEL should be WARNING, got {app.config.get('LOG_LEVEL')}\"
print('staging config OK')
" && pass "staging config correct (DEBUG=False, LOG_LEVEL=WARNING)" || fail "staging config incorrect"

# Production: DEBUG=False, LOG_LEVEL='ERROR'
python3 -c "
import sys, os
os.environ['SECRET_KEY'] = 'test-eval-secret-key-12345'
sys.path.insert(0, '.')
from app import create_app

app = create_app('production')
with app.app_context():
    assert app.config.get('DEBUG') is False, f\"prod DEBUG should be False, got {app.config.get('DEBUG')}\"
    assert app.config.get('LOG_LEVEL') == 'ERROR', f\"prod LOG_LEVEL should be ERROR, got {app.config.get('LOG_LEVEL')}\"
print('production config OK')
" && pass "production config correct (DEBUG=False, LOG_LEVEL=ERROR)" || fail "production config incorrect"

# --- AC: Default env uses development ---
python3 -c "
import sys
sys.path.insert(0, '.')
import os
if 'APP_ENV' in os.environ:
    del os.environ['APP_ENV']
from app import create_app

app = create_app()
with app.app_context():
    assert app.config.get('DEBUG') is True, f\"default should be DEBUG=True, got {app.config.get('DEBUG')}\"
    assert app.config.get('LOG_LEVEL') == 'DEBUG', f\"default LOG_LEVEL should be DEBUG, got {app.config.get('LOG_LEVEL')}\"
print('default env is development')
" && pass "default environment is development" || fail "default environment is not development"

# --- AC: Production SECRET_KEY not hardcoded (easy-to-miss) ---
python3 -c "
import sys, os, ast

# Check that production.py does not have a simple hardcoded SECRET_KEY string
with open('config/production.py') as f:
    content = f.read()

# Parse the AST to find SECRET_KEY assignment
tree = ast.parse(content)
for node in ast.walk(tree):
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == 'SECRET_KEY':
                # Should NOT be a plain string literal
                if isinstance(node.value, ast.Constant):
                    val = node.value.value
                    if isinstance(val, str):
                        print(f'SECRET_KEY is hardcoded as: {val}', file=sys.stderr)
                        sys.exit(1)

# Also verify it reads from env or raises
if 'os.environ' not in content and 'os.getenv' not in content and 'raise' not in content.lower():
    print('SECRET_KEY does not read from env var or raise error', file=sys.stderr)
    sys.exit(1)

print('production SECRET_KEY is not hardcoded')
" && pass "production SECRET_KEY not hardcoded (reads from env or raises)" || fail "production SECRET_KEY is hardcoded"

# --- AC: Existing tests still pass ---
python3 -m pytest tests/ -q --tb=short 2>&1 && pass "existing tests pass" || fail "existing tests fail"

# --- Summary ---
echo ""
echo "=== RESULTS: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
