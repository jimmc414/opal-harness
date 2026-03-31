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

# 1. textproc/formatters.py exists
check "formatters.py exists" test -f textproc/formatters.py

# 2. textproc/utils.py does NOT exist
check_not "utils.py does not exist" test -f textproc/utils.py

# 3. Direct import from formatters works
check "Import from formatters works" python -c "from textproc.formatters import slugify, truncate, capitalize_words, strip_html"

# 4. Re-exports via __init__ work
check "Re-exports via __init__ work" python -c "from textproc import slugify, truncate"

# 5. Parser import works
check "Parser import works" python -c "from textproc.parser import parse_content; assert parse_content('<p>Hi</p>') == 'Hi'"

# 6. Validator import works
check "Validator import works" python -c "from textproc.validator import is_valid_slug; assert is_valid_slug('hello-world')"

# 7. All existing tests pass
check "All existing tests pass" python -m pytest tests/ -q --tb=short

# 8. No remaining references to textproc.utils in any .py file
check_not "No references to textproc.utils in source" grep -r 'textproc\.utils' --include='*.py' .
check_not "No from textproc.utils imports in source" grep -r 'from textproc\.utils' --include='*.py' .

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
