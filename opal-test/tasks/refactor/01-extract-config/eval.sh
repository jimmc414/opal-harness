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
check "Existing tests pass" python -m pytest tests/ -q --tb=short

# 2. app/config.py exists
check "app/config.py exists" test -f app/config.py

# 3. config.py defines all required constants
check "config.py defines DB_URL" python -c "from app.config import DB_URL; assert DB_URL == 'postgresql://localhost:5432/myapp'"
check "config.py defines DB_POOL_SIZE" python -c "from app.config import DB_POOL_SIZE; assert DB_POOL_SIZE == 5"
check "config.py defines SECRET_KEY" python -c "from app.config import SECRET_KEY; assert SECRET_KEY == 'dev-secret-key-123'"
check "config.py defines API_TIMEOUT" python -c "from app.config import API_TIMEOUT; assert API_TIMEOUT == 30"
check "config.py defines API_MAX_RETRIES" python -c "from app.config import API_MAX_RETRIES; assert API_MAX_RETRIES == 3"
check "config.py defines PAGE_SIZE" python -c "from app.config import PAGE_SIZE; assert PAGE_SIZE == 20"

# 4. database.py does not contain the hardcoded DB URL string
check_not "database.py has no hardcoded DB URL" grep -q 'postgresql://localhost:5432/myapp' app/database.py

# 5. __init__.py does not contain dev-secret-key-123
check_not "__init__.py has no hardcoded secret key" grep -q 'dev-secret-key-123' app/__init__.py

# 6. routes.py does not contain page_size = 20 as a literal
check_not "routes.py has no hardcoded page_size = 20" grep -qE 'page_size\s*=\s*20' app/routes.py

# 7. api_client.py does not contain self.timeout = 30 as a literal
check_not "api_client.py has no hardcoded timeout = 30" grep -qE 'self\.timeout\s*=\s*30' app/api_client.py

# 8. api_client.py does not contain self.max_retries = 3 as a literal
check_not "api_client.py has no hardcoded max_retries = 3" grep -qE 'self\.max_retries\s*=\s*3' app/api_client.py

# 9. Behavior unchanged - verify through actual usage
check "Database URL unchanged" python -c "
from app.database import Database
db = Database()
assert db.connect() == 'postgresql://localhost:5432/myapp'
"

check "API client config unchanged" python -c "
from app.api_client import APIClient
c = APIClient('http://example.com')
cfg = c.get_config()
assert cfg['timeout'] == 30
assert cfg['max_retries'] == 3
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
