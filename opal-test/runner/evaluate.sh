#!/bin/bash
# Compare bare vs OPAL outcomes across all tasks
set -euo pipefail

TASKS_DIR="${1:-opal-test/tasks}"
RESULTS_DIR="${2:-opal-test/results}"

echo "=== Evaluation Summary ==="
echo ""

BARE_PASS=0; BARE_FAIL=0
OPAL_PASS=0; OPAL_FAIL=0

for task_dir in "$TASKS_DIR"/*/*; do
    [ -d "$task_dir" ] || continue
    task_id=$(basename "$task_dir")

    bare_result="SKIP"
    opal_result="SKIP"

    if [ -f "$RESULTS_DIR/bare/$task_id/result" ]; then
        bare_result=$(cat "$RESULTS_DIR/bare/$task_id/result")
        [ "$bare_result" = "PASS" ] && ((BARE_PASS++)) || ((BARE_FAIL++))
    fi

    if [ -f "$RESULTS_DIR/opal/$task_id/result" ]; then
        opal_result=$(cat "$RESULTS_DIR/opal/$task_id/result")
        [ "$opal_result" = "PASS" ] && ((OPAL_PASS++)) || ((OPAL_FAIL++))
    fi

    printf "%-40s  bare=%-4s  opal=%-4s\n" "$task_id" "$bare_result" "$opal_result"
done

echo ""
echo "Bare:  $BARE_PASS pass / $BARE_FAIL fail"
echo "OPAL:  $OPAL_PASS pass / $OPAL_FAIL fail"
