#!/usr/bin/env bash
# Phase 2 orchestrator: SWE-bench tasks — 5 tasks x 2 conditions = 10 runs.
# Uses real GitHub issues from SWE-bench Lite for harder differentiation.
# Runs bare first, then OPAL for each task.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/opal-test/results"

# Phase 2 tasks (all SWE-bench, all Tier 3)
TASKS=(
    "swebench/01-sympy-18621"
    "swebench/02-sympy-22005"
    "swebench/03-sympy-21847"
    "swebench/04-sympy-17655"
    "swebench/05-sympy-24152"
)

TASK_LABELS=(
    "sympy: BlockDiagMatrix conversion bug"
    "sympy: infinite solution detection"
    "sympy: itermonomials min_degrees bug"
    "sympy: Point * number exception"
    "sympy: TensorProduct expand bug"
)

RUN_NUM=0
TOTAL_RUNS=$((${#TASKS[@]} * 2))

# --- Environment check ---
echo "================================================================"
echo "  OPAL Phase 2: SWE-bench Real-World Tasks"
echo "  $TOTAL_RUNS runs (${#TASKS[@]} tasks x 2 conditions)"
echo "================================================================"
echo ""
echo "--- Environment Check ---"

READY=true
for cmd in python3 pytest claude git pip; do
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
echo "  Repo cache: ${SWEBENCH_REPO_CACHE:-$HOME/.cache/swebench-repos}"
echo ""
echo "  NOTE: First run will clone repos (may take several minutes per repo)."
echo "  Subsequent runs use cached clones."
echo ""

# Auto-handle parent CLAUDE.md interference
PARENT_CLAUDEMD="/mnt/c/python/CLAUDE.md"
PARENT_BACKUP="$PARENT_CLAUDEMD.phase2-backup"
if [[ -f "$PARENT_CLAUDEMD" ]]; then
    echo "  Renaming parent CLAUDE.md to prevent interference..."
    mv "$PARENT_CLAUDEMD" "$PARENT_BACKUP"
    trap 'mv "$PARENT_BACKUP" "$PARENT_CLAUDEMD" 2>/dev/null; echo "Restored parent CLAUDE.md"' EXIT
    echo "  [OK] Will restore on exit (including Ctrl+C)"
fi

read -p "Press Enter to begin Phase 2 runs..."

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
    echo "  Budget: \$15 | Tier 3 (SWE-bench)"
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
    echo ">>> Observe: Did the agent solve it? How did it navigate the large codebase?"
    echo ""
    read -p ">>> Press Enter to continue to OPAL condition..."

    # --- Run OPAL condition ---
    RUN_NUM=$((RUN_NUM + 1))
    echo ""
    echo "=============================================================="
    echo "  Run $RUN_NUM/$TOTAL_RUNS: $TASK_ID [OPAL]"
    echo "  ($TASK_LABEL)"
    echo "  Budget: \$30 | Tier 3 (SWE-bench)"
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
    echo ">>>   - How did the agent navigate the large codebase?"
    echo ">>>   - Did it hit dead ends and recover?"
    echo ">>>   - Did done.sh capture meaningful acceptance criteria?"
    echo ">>>   - Compare approach and outcome to the bare run."

    if [[ $RUN_NUM -lt $TOTAL_RUNS ]]; then
        echo ""
        read -p ">>> Press Enter to continue to next task..."
    fi
done

# --- Final Summary ---
echo ""
echo ""
echo "================================================================"
echo "  Phase 2 Final Summary (SWE-bench)"
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
echo "  Phase 2 complete."
echo "================================================================"
