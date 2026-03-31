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

# Run existing tests
check "Existing tests pass" python3 -m pytest tests/ -q --tb=short

# Check CHANGELOG.md exists
check "CHANGELOG.md exists" test -f CHANGELOG.md

# Check has a top-level header
check "CHANGELOG.md has a top-level header" python3 -c "
with open('CHANGELOG.md') as f:
    content = f.read()
lines = content.strip().split('\n')
found_header = False
for line in lines:
    if line.startswith('# '):
        found_header = True
        break
assert found_header, 'No top-level header (# ...) found'
"

# Check has Added category
check "Has 'Added' category as markdown header" python3 -c "
import re
with open('CHANGELOG.md') as f:
    content = f.read()
assert re.search(r'^#{1,3}\s+.*Added', content, re.MULTILINE), 'Missing Added as a markdown header (## Added)'
"

# Check has Fixed category as header
check "Has 'Fixed' category as markdown header" python3 -c "
import re
with open('CHANGELOG.md') as f:
    content = f.read()
assert re.search(r'^#{1,3}\s+.*Fixed', content, re.MULTILINE), 'Missing Fixed as a markdown header (## Fixed)'
"

# Check has Changed category as header
check "Has 'Changed' category as markdown header" python3 -c "
import re
with open('CHANGELOG.md') as f:
    content = f.read()
assert re.search(r'^#{1,3}\s+.*Changed', content, re.MULTILINE), 'Missing Changed as a markdown header (## Changed)'
"

# Check at least 5 entries (lines starting with - or *)
check "At least 5 changelog entries" python3 -c "
with open('CHANGELOG.md') as f:
    content = f.read()
entries = [line for line in content.split('\n') if line.strip().startswith(('-', '*')) and len(line.strip()) > 3]
assert len(entries) >= 5, f'Only found {len(entries)} entries, need at least 5'
"

# Check entries are in reverse chronological order (newest first)
# We verify by checking that feature/change entries appear before older ones
check "Entries appear in reverse chronological order" python3 -c "
with open('CHANGELOG.md') as f:
    content = f.read().lower()
# Rate limiting (newest feature) should appear before authentication (older feature)
rate_pos = content.find('rate limit')
auth_pos = content.find('authenticat')
if rate_pos >= 0 and auth_pos >= 0:
    assert rate_pos < auth_pos, 'Rate limiting should appear before authentication (reverse chronological)'
else:
    # At minimum check that the content exists
    assert rate_pos >= 0 or 'rate' in content, 'Rate limiting entry not found'
"

# Easy-to-miss: Initial commit must NOT appear as a feature
check "Initial commit is NOT listed as a feature" python3 -c "
with open('CHANGELOG.md') as f:
    content = f.read()
lines = content.split('\n')
in_added = False
for line in lines:
    lower = line.lower()
    # Track if we are in Added section
    if 'added' in lower and line.strip().startswith('#'):
        in_added = True
    elif line.strip().startswith('#') and 'added' not in lower:
        in_added = False
    # Check if Initial commit appears as a bullet in Added section
    if in_added and line.strip().startswith(('-', '*')) and 'initial commit' in lower:
        raise AssertionError('Initial commit should not be listed as an Added feature')

# Also check it is not listed anywhere as a feature entry
for line in lines:
    lower = line.lower().strip()
    if lower.startswith(('-', '*')) and 'initial commit' in lower:
        # Acceptable only if in a non-feature section or clearly marked as setup
        pass  # Lenient: just make sure it is not under Added
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
