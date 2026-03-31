#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

run_check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $description"
        FAIL=$((FAIL + 1))
    fi
}

# ── 1. Existing tests pass ──────────────────────────────────────────
run_check "Existing tests pass" python3 -m pytest tests/ -q

# ── 2. Multi-stage build (2+ FROM lines) ────────────────────────────
run_check "Multi-stage build (2+ FROM lines)" \
    bash -c 'from_count=$(grep -ci "^FROM " Dockerfile); [ "$from_count" -ge 2 ]'

# ── 3. Final base is slim or alpine ─────────────────────────────────
run_check "Final base is slim or alpine" \
    bash -c 'last_from=$(grep -i "^FROM " Dockerfile | tail -1 | tr "[:upper:]" "[:lower:]"); echo "$last_from" | grep -qE "(slim|alpine)"'

# ── 4. Requirements copied before source code (layer caching) ───────
run_check "Requirements copied before source code" \
    python3 -c "
import re
with open('Dockerfile') as f:
    lines = f.readlines()
# Find the last stage (after last FROM)
last_from_idx = 0
for i, l in enumerate(lines):
    if l.strip().upper().startswith('FROM'):
        last_from_idx = i
stage_lines = lines[last_from_idx:]
req_copy_idx = None
broad_copy_idx = None
for i, l in enumerate(stage_lines):
    stripped = l.strip().upper()
    if stripped.startswith('COPY') and 'REQUIREMENT' in stripped.upper():
        if req_copy_idx is None:
            req_copy_idx = i
    elif stripped.startswith('COPY') and 'REQUIREMENT' not in stripped.upper():
        broad_copy_idx = i
assert req_copy_idx is not None, 'No requirements COPY found'
assert broad_copy_idx is not None, 'No source COPY found'
assert req_copy_idx < broad_copy_idx, 'Requirements not copied before source'
"

# ── 5. No dev deps in final stage ───────────────────────────────────
run_check "No dev dependencies in final stage" \
    python3 -c "
with open('Dockerfile') as f:
    content = f.read()
parts = content.split('FROM')
final_stage = parts[-1]
assert 'requirements-dev' not in final_stage, 'Dev deps found in final stage'
assert len(parts) >= 3, 'Not enough FROM stages'
"

# ── 6. Non-root USER in final stage ─────────────────────────────────
run_check "Non-root USER in final stage" \
    python3 -c "
with open('Dockerfile') as f:
    content = f.read()
parts = content.split('FROM')
final_stage = parts[-1]
lines = final_stage.strip().split('\n')
user_lines = [l for l in lines if l.strip().upper().startswith('USER')]
assert len(user_lines) > 0, 'No USER directive in final stage'
for ul in user_lines:
    user_val = ul.strip().split()[-1].lower()
    assert user_val != 'root', 'USER is root'
"

# ── 7. .dockerignore has content ────────────────────────────────────
run_check ".dockerignore has content" \
    bash -c '[ -s .dockerignore ]'

# ── 8. .dockerignore excludes .git ──────────────────────────────────
run_check ".dockerignore excludes .git" \
    bash -c 'grep -q "\.git" .dockerignore'

# ── 9. .dockerignore excludes __pycache__ ───────────────────────────
run_check ".dockerignore excludes __pycache__" \
    bash -c 'grep -q "__pycache__" .dockerignore'

# ── 10. .dockerignore excludes tests ────────────────────────────────
run_check ".dockerignore excludes tests" \
    bash -c 'grep -qiE "(^tests/?$|^tests/|/tests/|tests)" .dockerignore'

# ── 10b. .dockerignore excludes *.pyc ───────────────────────────────
run_check ".dockerignore excludes *.pyc" \
    bash -c 'grep -q "\.pyc" .dockerignore'

# ── 10c. .dockerignore excludes .pytest_cache ───────────────────────
run_check ".dockerignore excludes .pytest_cache" \
    bash -c 'grep -q "\.pytest_cache" .dockerignore'

# ── 11. EXPOSE 5000 present ─────────────────────────────────────────
run_check "EXPOSE 5000 present" \
    bash -c 'grep -qi "EXPOSE.*5000" Dockerfile'

# ── 12. CMD or ENTRYPOINT present ───────────────────────────────────
run_check "CMD or ENTRYPOINT present" \
    bash -c 'grep -qiE "^(CMD|ENTRYPOINT)" Dockerfile'

# ── 13. WORKDIR set in final stage (easy to miss) ───────────────────
run_check "WORKDIR set in final stage" \
    python3 -c "
with open('Dockerfile') as f:
    content = f.read()
parts = content.split('FROM')
assert len(parts) >= 3, 'Must be multi-stage to have a distinct final stage'
final_stage = parts[-1]
lines = final_stage.strip().split('\n')
workdir_lines = [l for l in lines if l.strip().upper().startswith('WORKDIR')]
assert len(workdir_lines) > 0, 'No WORKDIR in final stage'
"

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "  TOTAL: $((PASS + FAIL))  |  PASS: $PASS  |  FAIL: $FAIL"
echo "═══════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
