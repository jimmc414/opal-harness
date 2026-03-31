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

check_not() {
    local desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

# 1. All existing tests pass
check "All existing tests pass" python -m pytest tests/ -q --tb=short

# 2. legacy.py does not exist
check_not "legacy.py removed" test -f mathlib/legacy.py

# 3. Public API still works
check "Public API imports work" python -c "from mathlib import add, subtract, multiply, divide, mean, median"

# 4-6. Dead functions removed from core.py
check_not "deprecated_power removed from core.py" grep -q 'def deprecated_power' mathlib/core.py
check_not "experimental_factorial removed from core.py" grep -q 'def experimental_factorial' mathlib/core.py
check_not "_internal_log removed from core.py" grep -q 'def _internal_log' mathlib/core.py

# 7-9. Unused imports removed from core.py
check_not "import os removed from core.py" grep -qE '^import os$' mathlib/core.py
check_not "import sys removed from core.py" grep -qE '^import sys$' mathlib/core.py
check_not "import json removed from core.py" grep -qE '^import json$' mathlib/core.py

# 10. import math removed from core.py (was only used by deprecated_power)
check_not "import math removed from core.py" grep -qE '^import math$' mathlib/core.py

# 11-12. Unused imports removed from stats.py
check_not "import csv removed from stats.py" grep -qE '^import csv$' mathlib/stats.py
check_not "import statistics removed from stats.py" grep -qE '^import statistics$' mathlib/stats.py

# 13-14. Dead functions removed from stats.py
check_not "variance removed from stats.py" grep -q 'def variance' mathlib/stats.py
check_not "correlation removed from stats.py" grep -q 'def correlation' mathlib/stats.py

# 15. deprecated_power not imported in stats.py
check_not "deprecated_power import removed from stats.py" grep -q 'deprecated_power' mathlib/stats.py

# 16. Core functions still work correctly
check "add still works" python -c "from mathlib.core import add; assert add(2,3) == 5"
check "divide still works" python -c "from mathlib.core import divide; assert divide(10,2) == 5.0"
check "mean still works" python -c "from mathlib.stats import mean; assert mean([1,2,3]) == 2.0"
check "median still works" python -c "from mathlib.stats import median; assert median([1,2,3]) == 2"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
