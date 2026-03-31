#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# --- AC: First ADR file exists ---
ADR1="docs/adr/001-database-choice.md"
if [ -f "$ADR1" ]; then
    pass "ADR file exists at $ADR1"
else
    fail "ADR file missing at $ADR1"
fi

# --- AC: First ADR has required sections ---
if [ -f "$ADR1" ]; then
    ADR1_CONTENT=$(cat "$ADR1")

    for section in "Title" "Status" "Context" "Decision" "Consequences"; do
        if echo "$ADR1_CONTENT" | grep -qi "^#.*${section}\|^## *${section}\|^### *${section}"; then
            pass "ADR 001 has $section section"
        else
            fail "ADR 001 missing $section section"
        fi
    done

    # --- AC: ADR 001 explains SQLite choice ---
    if echo "$ADR1_CONTENT" | grep -qi "sqlite"; then
        pass "ADR 001 mentions SQLite"
    else
        fail "ADR 001 does not mention SQLite"
    fi

    # --- AC: ADR 001 mentions trade-offs ---
    if echo "$ADR1_CONTENT" | grep -qiE "trade.?off|simplicity|scalab|file.?based|server.?based|lightweight|portab|limitation"; then
        pass "ADR 001 discusses trade-offs"
    else
        fail "ADR 001 does not discuss trade-offs"
    fi
else
    fail "ADR 001 sections check skipped (file missing)"
    fail "ADR 001 SQLite check skipped (file missing)"
    fail "ADR 001 trade-offs check skipped (file missing)"
fi

# --- AC: Second ADR file exists ---
ADR2="docs/adr/002-sync-processing.md"
if [ -f "$ADR2" ]; then
    pass "ADR file exists at $ADR2"
else
    fail "ADR file missing at $ADR2"
fi

# --- AC: Second ADR has required sections ---
if [ -f "$ADR2" ]; then
    ADR2_CONTENT=$(cat "$ADR2")

    for section in "Title" "Status" "Context" "Decision" "Consequences"; do
        if echo "$ADR2_CONTENT" | grep -qi "^#.*${section}\|^## *${section}\|^### *${section}"; then
            pass "ADR 002 has $section section"
        else
            fail "ADR 002 missing $section section"
        fi
    done

    # --- AC: ADR 002 explains sync processing ---
    if echo "$ADR2_CONTENT" | grep -qiE "synchron|sync"; then
        pass "ADR 002 mentions synchronous processing"
    else
        fail "ADR 002 does not mention synchronous processing"
    fi
else
    fail "ADR 002 sections check skipped (file missing)"
    fail "ADR 002 sync processing check skipped (file missing)"
fi

# --- AC: Each ADR has Status field with valid value (easy-to-miss) ---
# Check the line immediately following the Status header, not the whole file
if [ -f "$ADR1" ]; then
    python3 -c "
import re
with open('$ADR1') as f:
    lines = f.readlines()
valid = {'proposed', 'accepted', 'deprecated', 'superseded'}
found = False
for i, line in enumerate(lines):
    if re.match(r'^#{1,3}\s+.*[Ss]tatus', line):
        # Check next non-empty line(s) for a valid status word
        for j in range(i+1, min(i+4, len(lines))):
            lower = lines[j].strip().lower()
            if any(s in lower for s in valid):
                found = True
                break
            if lines[j].strip().startswith('#'):
                break
        break
assert found, 'ADR 001: no valid status value found after Status header'
" && pass "ADR 001 has valid Status value" || fail "ADR 001 missing valid Status (must be one of: proposed, accepted, deprecated, superseded)"
fi

if [ -f "$ADR2" ]; then
    python3 -c "
import re
with open('$ADR2') as f:
    lines = f.readlines()
valid = {'proposed', 'accepted', 'deprecated', 'superseded'}
found = False
for i, line in enumerate(lines):
    if re.match(r'^#{1,3}\s+.*[Ss]tatus', line):
        for j in range(i+1, min(i+4, len(lines))):
            lower = lines[j].strip().lower()
            if any(s in lower for s in valid):
                found = True
                break
            if lines[j].strip().startswith('#'):
                break
        break
assert found, 'ADR 002: no valid status value found after Status header'
" && pass "ADR 002 has valid Status value" || fail "ADR 002 missing valid Status (must be one of: proposed, accepted, deprecated, superseded)"
fi

# --- AC: Existing tests still pass ---
python3 -m pytest tests/ -q --tb=short 2>&1 && pass "existing tests pass" || fail "existing tests fail"

# --- Summary ---
echo ""
echo "=== RESULTS: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
