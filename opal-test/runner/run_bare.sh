#!/bin/bash
# Run a task without the OPAL harness (bare baseline)
set -euo pipefail

TASK_DIR="$1"
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

# Copy repo into clean working directory
cp -r "$TASK_DIR/repo/"* "$WORK_DIR/"

echo "=== Bare Baseline ==="
echo "Task: $TASK_DIR"
echo "Work dir: $WORK_DIR"

# Provide task.md as prompt to the agent
TASK_CONTENT=$(cat "$TASK_DIR/task.md")

# TODO: Invoke LLM agent with TASK_CONTENT as prompt
# Agent gets: terminal, file read/write/edit access
# No harness files, no .opal/ directory
# Hard timeout: 30 minutes

echo "Agent execution placeholder — integrate with your LLM runner"

# Evaluate
export WORK_DIR
bash "$TASK_DIR/eval.sh"
EXIT_CODE=$?

echo "eval.sh exit code: $EXIT_CODE"
exit $EXIT_CODE
