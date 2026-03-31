#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

CI_FILE=".github/workflows/ci.yml"

# --- AC: CI file exists ---
if [ -f "$CI_FILE" ]; then
    pass "CI workflow file exists"
else
    fail "CI workflow file missing at $CI_FILE"
    echo "=== RESULTS: $PASS passed, $FAIL failed ==="
    exit 1
fi

CI_CONTENT=$(cat "$CI_FILE")

# --- AC: Installs pytest (not pytst) ---
if echo "$CI_CONTENT" | grep -q 'pip install.*pytest' && ! echo "$CI_CONTENT" | grep -q 'pip install.*pytst'; then
    pass "workflow installs pytest correctly"
else
    fail "workflow does not install pytest correctly (found pytst or missing pytest)"
fi

# --- AC: Runs pytest tests/ (not pytset) ---
if echo "$CI_CONTENT" | grep -q 'pytest tests/' && ! echo "$CI_CONTENT" | grep -q 'pytset'; then
    pass "workflow runs pytest tests/ correctly"
else
    fail "workflow does not run 'pytest tests/' correctly (found pytset or missing pytest)"
fi

# --- AC: Triggers on push and pull_request to main ---
python3 -c "
import sys
try:
    import yaml
    with open('$CI_FILE') as f:
        data = yaml.safe_load(f.read())
    on = data.get(True, data.get('on', {}))
    push_branches = on.get('push', {}).get('branches', [])
    pr_branches = on.get('pull_request', {}).get('branches', [])
    if 'main' not in push_branches:
        print('push trigger missing main', file=sys.stderr)
        sys.exit(1)
    if 'main' not in pr_branches:
        print('pull_request trigger missing main', file=sys.stderr)
        sys.exit(1)
except ImportError:
    content = open('$CI_FILE').read()
    if 'push:' not in content or 'pull_request:' not in content:
        sys.exit(1)
    if 'main' not in content:
        sys.exit(1)
" && pass "workflow triggers on push and PR to main" || fail "workflow triggers not preserved for push/PR to main"

# --- AC: Python version is set ---
if echo "$CI_CONTENT" | grep -q 'python-version'; then
    pass "Python version is set in workflow"
else
    fail "Python version not set in workflow"
fi

# --- AC: Lint step with flake8 preserved ---
if echo "$CI_CONTENT" | grep -q 'flake8'; then
    pass "flake8 lint step preserved"
else
    fail "flake8 lint step missing"
fi

# --- AC: Install dependencies step name is sensible (easy-to-miss) ---
# The step that installs pytest should have a name that makes sense
python3 -c "
import sys
try:
    import yaml
    with open('$CI_FILE') as f:
        data = yaml.safe_load(f.read())
    steps = data.get('jobs', {}).get('test', {}).get('steps', [])
    for step in steps:
        run_cmd = step.get('run', '')
        name = step.get('name', '')
        if 'pip install' in run_cmd and 'pytest' in run_cmd:
            # The name should not reference wrong package
            if 'pytst' in name.lower():
                print('Step name references wrong package', file=sys.stderr)
                sys.exit(1)
            # Name should exist and be descriptive
            if not name:
                print('Install step has no name', file=sys.stderr)
                sys.exit(1)
            break
except ImportError:
    pass  # Skip if no yaml available, basic check is enough
" && pass "install step name is accurate" || fail "install step name is inaccurate or missing"

# --- AC: Local tests still pass ---
python3 -m pytest tests/ -q --tb=short 2>&1 && pass "local tests pass" || fail "local tests fail"

# --- Summary ---
echo ""
echo "=== RESULTS: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
