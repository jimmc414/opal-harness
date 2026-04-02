#!/usr/bin/env bash
# Run a single task under bare or OPAL condition.
# Usage: run_task.sh <task_id> <condition: bare|opal>
# Example: run_task.sh bugfix/01-whitespace-strip bare
set -euo pipefail

TASK_ID="$1"
CONDITION="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TASKS_DIR="$PROJECT_ROOT/opal-test/tasks"
RESULTS_DIR="$PROJECT_ROOT/opal-test/results"

# Convert task_id path (bugfix/01-whitespace-strip) to result dir name (bugfix-01-whitespace-strip)
RESULT_ID="${TASK_ID//\//-}"
TASK_DIR="$TASKS_DIR/$TASK_ID"
RESULT_DIR="$RESULTS_DIR/$CONDITION/$RESULT_ID"
WORKSPACE="$RESULT_DIR/workspace"

if [[ ! -d "$TASK_DIR" ]]; then
    echo "ERROR: Task directory not found: $TASK_DIR" >&2
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo "ERROR: 'claude' CLI not found in PATH" >&2
    exit 1
fi

# Set budget based on condition and task type
if [[ "$TASK_ID" == swebench/* ]]; then
    # SWE-bench tasks are harder, need higher budgets
    if [[ "$CONDITION" == "bare" ]]; then
        BUDGET=15
    else
        BUDGET=30
    fi
else
    if [[ "$CONDITION" == "bare" ]]; then
        BUDGET=5
    else
        BUDGET=15
    fi
fi

echo "================================================================"
echo "  Task:      $TASK_ID"
echo "  Condition: $CONDITION"
echo "  Budget:    \$$BUDGET"
echo "  Results:   $RESULT_DIR"
echo "================================================================"

# Clean previous run if exists
rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"

# Setup workspace
"$SCRIPT_DIR/setup_workspace.sh" "$TASK_DIR" "$CONDITION" "$WORKSPACE"

# Build prompt
if [[ "$CONDITION" == "bare" ]]; then
    PROMPT=$(cat "$TASK_DIR/task.md")
else
    PROMPT="Read .opal/harness.md and begin work on the task described in .opal/task.md."
fi

# Invoke Claude Code CLI
# No --bare: it disables OAuth and breaks Max subscription auth.
# CLAUDE.md auto-discovery works normally:
#   OPAL workspace has CLAUDE.md -> agent reads it -> follows harness.md
#   Bare workspace has no CLAUDE.md -> agent gets only ~/.claude/CLAUDE.md
# Parent /mnt/c/python/CLAUDE.md must be renamed before running (see phase1.sh).
echo ""
echo "--- Invoking Claude Code CLI ---"
TIMESTAMP_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)

ORIG_DIR="$(pwd)"
cd "$WORKSPACE"

set +e
claude -p \
    --model opus \
    --dangerously-skip-permissions \
    --output-format stream-json \
    --max-budget-usd "$BUDGET" \
    "$PROMPT" \
    2>&1 | tee "$RESULT_DIR/transcript.jsonl"
CLAUDE_EXIT=${PIPESTATUS[0]}
set -e

cd "$ORIG_DIR"

TIMESTAMP_END=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo ""
echo "--- Claude Code exited with code: $CLAUDE_EXIT ---"

# Archive .opal/ for OPAL condition (before eval potentially modifies things)
if [[ "$CONDITION" == "opal" && -d "$WORKSPACE/.opal" ]]; then
    cp -r "$WORKSPACE/.opal" "$RESULT_DIR/opal_archive"
    echo "Archived .opal/ to $RESULT_DIR/opal_archive/"
fi

# Run eval.sh
echo ""
echo "--- Running eval.sh ---"
if [[ "$CONDITION" == "bare" ]]; then
    export WORK_DIR="$WORKSPACE"
else
    export WORK_DIR="$WORKSPACE/work"
fi

set +e
bash "$TASK_DIR/eval.sh"
EVAL_EXIT=$?
set -e

# Write result
if [[ $EVAL_EXIT -eq 0 ]]; then
    echo "PASS" > "$RESULT_DIR/result"
    echo "Result: PASS"
else
    echo "FAIL" > "$RESULT_DIR/result"
    echo "Result: FAIL (eval.sh exit code: $EVAL_EXIT)"
fi

# Write metrics.json
cat > "$RESULT_DIR/metrics.json" << METRICSEOF
{
  "task_id": "$RESULT_ID",
  "condition": "$CONDITION",
  "eval_exit_code": $EVAL_EXIT,
  "claude_exit_code": $CLAUDE_EXIT,
  "budget_usd": $BUDGET,
  "timestamp_start": "$TIMESTAMP_START",
  "timestamp_end": "$TIMESTAMP_END"
}
METRICSEOF

echo ""
echo "Done: $RESULT_ID ($CONDITION) -> $(cat "$RESULT_DIR/result")"
