#!/usr/bin/env bash
# Phase 1 orchestrator: 5 tasks x 2 conditions = 10 runs.
# Runs bare first, then OPAL for each task (prevents OPAL knowledge from biasing bare observation).
# Pauses between each run for manual observation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/opal-test/results"

# Phase 1 tasks (simplest -> hardest)
TASKS=(
    "bugfix/01-whitespace-strip"
    "bugfix/08-regex-backtrack"
    "bugfix/10-float-precision"
    "bugfix/09-timezone-dst"
    "refactor/07-split-module"
)

TASK_LABELS=(
    "Tier 1, direct-solve"
    "Tier 2, dead-ends"
    "Tier 2, mid-check"
    "Tier 2, donesh-bug"
    "Tier 3, multi-file"
)

RUN_NUM=0
TOTAL_RUNS=$((${#TASKS[@]} * 2))

# --- Environment check ---
echo "================================================================"
echo "  OPAL Phase 1: Manual Validation Runner"
echo "  $TOTAL_RUNS runs (${#TASKS[@]} tasks x 2 conditions)"
echo "================================================================"
echo ""
echo "--- Environment Check ---"

READY=true
for cmd in python3 pytest claude; do
    if command -v "$cmd" &>/dev/null; then
        echo "  [OK] $cmd: $(command -v "$cmd")"
    else
        echo "  [MISSING] $cmd not found"
        READY=false
    fi
done

if [[ "$READY" != "true" ]]; then
    echo ""
    echo "ERROR: Missing required tools. Aborting." >&2
    exit 1
fi

echo ""
echo "  Claude version: $(claude --version 2>/dev/null || echo 'unknown')"
echo "  Python version: $(python3 --version 2>/dev/null)"
echo ""

# Auto-handle parent CLAUDE.md interference
PARENT_CLAUDEMD="/mnt/c/python/CLAUDE.md"
PARENT_BACKUP="$PARENT_CLAUDEMD.phase1-backup"
if [[ -f "$PARENT_CLAUDEMD" ]]; then
    echo "  Renaming parent CLAUDE.md to prevent interference..."
    mv "$PARENT_CLAUDEMD" "$PARENT_BACKUP"
    trap 'mv "$PARENT_BACKUP" "$PARENT_CLAUDEMD" 2>/dev/null; echo "Restored parent CLAUDE.md"' EXIT
    echo "  [OK] Will restore on exit (including Ctrl+C)"
fi

read -p "Press Enter to begin Phase 1 runs..."

# --- Main loop ---
for i in "${!TASKS[@]}"; do
    TASK_ID="${TASKS[$i]}"
    TASK_LABEL="${TASK_LABELS[$i]}"
    RESULT_ID="${TASK_ID//\//-}"

    # --- Run BARE condition first ---
    RUN_NUM=$((RUN_NUM + 1))
    echo ""
    echo "=============================================================="
    echo "  Run $RUN_NUM/$TOTAL_RUNS: $TASK_ID [BARE]"
    echo "  ($TASK_LABEL)"
    echo "=============================================================="
    echo ""

    set +e
    "$SCRIPT_DIR/run_task.sh" "$TASK_ID" "bare"
    set -e

    BARE_RESULT="FAIL"
    if [[ -f "$RESULTS_DIR/bare/$RESULT_ID/result" ]]; then
        BARE_RESULT=$(cat "$RESULTS_DIR/bare/$RESULT_ID/result")
    fi

    echo ""
    echo ">>> BARE run complete: $RESULT_ID -> $BARE_RESULT"
    echo ">>> Review the transcript at: $RESULTS_DIR/bare/$RESULT_ID/transcript.jsonl"
    echo ">>> Observe: Did the agent solve it? How did it approach the problem?"
    echo ""
    read -p ">>> Press Enter to continue to OPAL condition..."

    # --- Run OPAL condition ---
    RUN_NUM=$((RUN_NUM + 1))
    echo ""
    echo "=============================================================="
    echo "  Run $RUN_NUM/$TOTAL_RUNS: $TASK_ID [OPAL]"
    echo "  ($TASK_LABEL)"
    echo "=============================================================="
    echo ""

    set +e
    "$SCRIPT_DIR/run_task.sh" "$TASK_ID" "opal"
    set -e

    OPAL_RESULT="FAIL"
    if [[ -f "$RESULTS_DIR/opal/$RESULT_ID/result" ]]; then
        OPAL_RESULT=$(cat "$RESULTS_DIR/opal/$RESULT_ID/result")
    fi

    # Run artifact check for OPAL
    echo ""
    echo "--- OPAL Artifact Check ---"
    set +e
    "$SCRIPT_DIR/check_artifacts.sh" "$RESULTS_DIR/opal/$RESULT_ID"
    set -e

    echo ""
    echo ">>> OPAL run complete: $RESULT_ID -> $OPAL_RESULT"
    echo ">>> Review: transcript, artifact check, and .opal/ archive"
    echo ">>>   Transcript: $RESULTS_DIR/opal/$RESULT_ID/transcript.jsonl"
    echo ">>>   Archive:    $RESULTS_DIR/opal/$RESULT_ID/opal_archive/"
    echo ">>> Key questions:"
    echo ">>>   - Did the agent read harness.md?"
    echo ">>>   - Did it maintain state.md across cycles?"
    echo ">>>   - Did done.sh capture all acceptance criteria?"
    echo ">>>   - Compare approach to the bare run."

    if [[ $RUN_NUM -lt $TOTAL_RUNS ]]; then
        echo ""
        read -p ">>> Press Enter to continue to next task..."
    fi
done

# --- Final Summary ---
echo ""
echo ""
echo "================================================================"
echo "  Phase 1 Final Summary"
echo "================================================================"
echo ""
printf "  %-40s  %-6s  %-6s\n" "TASK" "BARE" "OPAL"
printf "  %-40s  %-6s  %-6s\n" "$(printf '%0.s-' {1..40})" "------" "------"

for TASK_ID in "${TASKS[@]}"; do
    RESULT_ID="${TASK_ID//\//-}"
    BARE="SKIP"
    OPAL="SKIP"
    [[ -f "$RESULTS_DIR/bare/$RESULT_ID/result" ]] && BARE=$(cat "$RESULTS_DIR/bare/$RESULT_ID/result")
    [[ -f "$RESULTS_DIR/opal/$RESULT_ID/result" ]] && OPAL=$(cat "$RESULTS_DIR/opal/$RESULT_ID/result")
    printf "  %-40s  %-6s  %-6s\n" "$RESULT_ID" "$BARE" "$OPAL"
done

BARE_PASS=0; BARE_FAIL=0; OPAL_PASS=0; OPAL_FAIL=0
for TASK_ID in "${TASKS[@]}"; do
    RESULT_ID="${TASK_ID//\//-}"
    if [[ -f "$RESULTS_DIR/bare/$RESULT_ID/result" ]]; then
        if [[ $(cat "$RESULTS_DIR/bare/$RESULT_ID/result") == "PASS" ]]; then
            BARE_PASS=$((BARE_PASS + 1))
        else
            BARE_FAIL=$((BARE_FAIL + 1))
        fi
    fi
    if [[ -f "$RESULTS_DIR/opal/$RESULT_ID/result" ]]; then
        if [[ $(cat "$RESULTS_DIR/opal/$RESULT_ID/result") == "PASS" ]]; then
            OPAL_PASS=$((OPAL_PASS + 1))
        else
            OPAL_FAIL=$((OPAL_FAIL + 1))
        fi
    fi
done

echo ""
echo "  Bare: $BARE_PASS pass / $BARE_FAIL fail"
echo "  OPAL: $OPAL_PASS pass / $OPAL_FAIL fail"
echo ""
echo "  Results directory: $RESULTS_DIR"
echo "  Run compare.py for detailed metrics:"
echo "    python3 $PROJECT_ROOT/opal-test/analysis/compare.py $PROJECT_ROOT/opal-test"
echo ""
echo "================================================================"
echo "  Phase 1 complete."
echo "================================================================"
