#!/bin/bash
# Run a task with the OPAL harness
set -euo pipefail

TASK_DIR="$1"
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

# Copy repo into work/
mkdir -p "$WORK_DIR/work"
cp -r "$TASK_DIR/repo/"* "$WORK_DIR/work/"

# Initialize .opal/ workspace
mkdir -p "$WORK_DIR/.opal"
cp "$TASK_DIR/task.md" "$WORK_DIR/.opal/task.md"

echo "=== OPAL Condition ==="
echo "Task: $TASK_DIR"
echo "Work dir: $WORK_DIR"

# TODO: Copy harness.md into .opal/
# TODO: Ensure CLAUDE.md contains harness reference
# TODO: Invoke LLM agent under OPAL protocol

echo "Agent execution placeholder — integrate with your LLM runner"

# Evaluate against work/ directory
export WORK_DIR="$WORK_DIR/work"
bash "$TASK_DIR/eval.sh"
EXIT_CODE=$?

echo "eval.sh exit code: $EXIT_CODE"
exit $EXIT_CODE
