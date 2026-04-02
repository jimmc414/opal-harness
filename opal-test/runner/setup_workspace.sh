#!/usr/bin/env bash
# Initialize a task workspace for bare or OPAL condition.
# Usage: setup_workspace.sh <task_dir> <condition: bare|opal> <output_dir>
set -euo pipefail

TASK_DIR="$1"
CONDITION="$2"
OUTPUT_DIR="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HARNESS_MD="$PROJECT_ROOT/spec/harness.md"

if [[ "$CONDITION" != "bare" && "$CONDITION" != "opal" ]]; then
    echo "ERROR: condition must be 'bare' or 'opal', got '$CONDITION'" >&2
    exit 1
fi

if [[ ! -d "$TASK_DIR/repo" && ! -f "$TASK_DIR/setup_repo.sh" ]]; then
    echo "ERROR: $TASK_DIR/repo or setup_repo.sh not found" >&2
    exit 1
fi

if [[ ! -f "$HARNESS_MD" ]]; then
    echo "ERROR: harness.md not found at $HARNESS_MD" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

if [[ "$CONDITION" == "bare" ]]; then
    # BARE: copy repo/ contents or clone via setup_repo.sh
    if [[ -d "$TASK_DIR/repo" ]]; then
        cp -r "$TASK_DIR/repo/"* "$OUTPUT_DIR/" 2>/dev/null || true
        cp -r "$TASK_DIR/repo/".[!.]* "$OUTPUT_DIR/" 2>/dev/null || true
    else
        bash "$TASK_DIR/setup_repo.sh" "$OUTPUT_DIR"
    fi
    echo "Bare workspace initialized: $OUTPUT_DIR"
    exit 0
fi

# --- OPAL condition ---

# Create work/ with repo contents
mkdir -p "$OUTPUT_DIR/work"
if [[ -d "$TASK_DIR/repo" ]]; then
    cp -r "$TASK_DIR/repo/"* "$OUTPUT_DIR/work/" 2>/dev/null || true
    cp -r "$TASK_DIR/repo/".[!.]* "$OUTPUT_DIR/work/" 2>/dev/null || true
else
    bash "$TASK_DIR/setup_repo.sh" "$OUTPUT_DIR/work"
fi

# Create .opal/ directory structure
mkdir -p "$OUTPUT_DIR/.opal/checks"

# Copy harness.md
cp "$HARNESS_MD" "$OUTPUT_DIR/.opal/harness.md"

# Copy task.md
cp "$TASK_DIR/task.md" "$OUTPUT_DIR/.opal/task.md"

# Extract max cycles from task.md (default 15)
MAX_CYCLES=15
if grep -qP 'Max cycles:\s*\d+' "$TASK_DIR/task.md" 2>/dev/null; then
    MAX_CYCLES=$(grep -oP 'Max cycles:\s*\K\d+' "$TASK_DIR/task.md")
fi

# Initialize state.md with all 7 required fields
cat > "$OUTPUT_DIR/.opal/state.md" << STATEEOF
## State

**Phase:** ORIENT
**Cycle:** 1 / $MAX_CYCLES
**Summary:** Task not yet started.
**Next Action:** Read .opal/harness.md to understand the operating protocol.
**Blocking Issues:** None
**Artifacts:** None
**Check Command:** \`bash .opal/checks/done.sh\`
STATEEOF

# Initialize plan.md
echo "Not yet created." > "$OUTPUT_DIR/.opal/plan.md"

# Initialize log.md (empty)
touch "$OUTPUT_DIR/.opal/log.md"

# Initialize done.sh (placeholder, exits 1)
cat > "$OUTPUT_DIR/.opal/checks/done.sh" << 'DONEEOF'
#!/usr/bin/env bash
# Acceptance: (not yet defined)
exit 1
DONEEOF
chmod +x "$OUTPUT_DIR/.opal/checks/done.sh"

# Create CLAUDE.md with harness reference
cat > "$OUTPUT_DIR/CLAUDE.md" << 'CLAUDEEOF'
Read and follow the operating protocol in .opal/harness.md before doing anything else.
CLAUDEEOF

echo "OPAL workspace initialized: $OUTPUT_DIR"
