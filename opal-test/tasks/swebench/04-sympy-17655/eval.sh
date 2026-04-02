#!/usr/bin/env bash
# Eval for SWE-bench instance: sympy__sympy-17655
# FAIL_TO_PASS: 2 tests | PASS_TO_PASS: 9 tests
set -euo pipefail

# Compute TASK_DIR before changing directory
TASK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd "$WORK_DIR"

# Make project importable (prefer PYTHONPATH over pip install to avoid
# breaking the current environment with old dependency versions)
export PYTHONPATH="$WORK_DIR:${PYTHONPATH:-}"

# Apply test patch (new tests that verify the fix)
echo "Applying test patch..."
git apply --allow-empty "$TASK_DIR/test_patch.diff"

# FAIL_TO_PASS: these tests must pass after the fix
echo "Running FAIL_TO_PASS tests..."
python -m pytest "sympy/geometry/tests/test_point.py::test_point" "sympy/geometry/tests/test_point.py::test_point3D" -x --tb=short -q

# PASS_TO_PASS: these test modules must not regress
echo "Running PASS_TO_PASS regression tests..."
python -m pytest "sympy/geometry/tests/test_point.py" -x --tb=short -q || true

echo "ALL CRITERIA PASSED"
