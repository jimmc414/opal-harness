#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

run_check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $description"
        FAIL=$((FAIL + 1))
    fi
}

# 1. All tests pass
run_check "All tests pass" python3 -m pytest tests/ -x -q

# 2. UserService.__init__ accepts logger and cache params
run_check "UserService constructor requires logger and cache" python3 -c "
from services.user_service import UserService
from services.logger import Logger
from services.cache import Cache
svc = UserService(Logger(), Cache())
assert hasattr(svc, 'logger') or hasattr(svc, '_logger'), 'UserService missing logger attribute'
assert hasattr(svc, 'cache') or hasattr(svc, '_cache'), 'UserService missing cache attribute'
"

# 3. OrderService.__init__ accepts logger, cache, mailer params
run_check "OrderService constructor requires logger, cache, mailer" python3 -c "
from services.order_service import OrderService
from services.logger import Logger
from services.cache import Cache
from services.mailer import Mailer
svc = OrderService(Logger(), Cache(), Mailer())
assert hasattr(svc, 'logger') or hasattr(svc, '_logger'), 'OrderService missing logger'
assert hasattr(svc, 'cache') or hasattr(svc, '_cache'), 'OrderService missing cache'
assert hasattr(svc, 'mailer') or hasattr(svc, '_mailer'), 'OrderService missing mailer'
"

# 4. No 'from services.logger import logger' in user_service.py
run_check "No global logger import in user_service.py" python3 -c "
with open('services/user_service.py') as f:
    content = f.read()
assert 'from services.logger import logger' not in content, 'user_service.py still imports global logger'
"

# 5. No 'from services.cache import cache' in user_service.py
run_check "No global cache import in user_service.py" python3 -c "
with open('services/user_service.py') as f:
    content = f.read()
assert 'from services.cache import cache' not in content, 'user_service.py still imports global cache'
"

# 6. No 'from services.logger import logger' in order_service.py
run_check "No global logger import in order_service.py" python3 -c "
with open('services/order_service.py') as f:
    content = f.read()
assert 'from services.logger import logger' not in content, 'order_service.py still imports global logger'
"

# 7. No 'from services.cache import cache' in order_service.py
run_check "No global cache import in order_service.py" python3 -c "
with open('services/order_service.py') as f:
    content = f.read()
assert 'from services.cache import cache' not in content, 'order_service.py still imports global cache'
"

# 8. No 'from services.mailer import mailer' in order_service.py
run_check "No global mailer import in order_service.py" python3 -c "
with open('services/order_service.py') as f:
    content = f.read()
assert 'from services.mailer import mailer' not in content, 'order_service.py still imports global mailer'
"

# 9. UserService() without args raises TypeError (requires injection)
run_check "UserService() without args raises TypeError" python3 -c "
from services.user_service import UserService
try:
    UserService()
    raise AssertionError('UserService() should have raised TypeError')
except TypeError:
    pass
"

# 10. OrderService() without args raises TypeError (requires injection)
run_check "OrderService() without args raises TypeError" python3 -c "
from services.order_service import OrderService
try:
    OrderService()
    raise AssertionError('OrderService() should have raised TypeError')
except TypeError:
    pass
"

# 11. Logger class still exists in services.logger
run_check "Logger class still exists" python3 -c "
from services.logger import Logger
assert callable(Logger), 'Logger class missing'
lg = Logger()
lg.info('test')
assert len(lg.get_logs()) == 1
"

# 12. Cache class still exists in services.cache
run_check "Cache class still exists" python3 -c "
from services.cache import Cache
assert callable(Cache), 'Cache class missing'
c = Cache()
c.set('k', 'v')
assert c.get('k') == 'v'
"

# 13. Mailer class still exists in services.mailer
run_check "Mailer class still exists" python3 -c "
from services.mailer import Mailer
assert callable(Mailer), 'Mailer class missing'
m = Mailer()
m.send('a@b.com', 'subj', 'body')
assert len(m.get_sent()) == 1
"

# 14. Injected services actually work end-to-end
run_check "Injected UserService works end-to-end" python3 -c "
from services.user_service import UserService
from services.logger import Logger
from services.cache import Cache
lg = Logger()
ca = Cache()
svc = UserService(lg, ca)
user = svc.create_user('testuser', 'test@test.com')
assert user['username'] == 'testuser'
assert ca.get('user:testuser') is not None
assert any('Created user' in log['message'] for log in lg.get_logs())
"

# 15. Injected OrderService works end-to-end
run_check "Injected OrderService works end-to-end" python3 -c "
from services.order_service import OrderService
from services.logger import Logger
from services.cache import Cache
from services.mailer import Mailer
lg = Logger()
ca = Cache()
ml = Mailer()
svc = OrderService(lg, ca, ml)
order = svc.create_order('O-1', 'x@y.com', ['item'])
assert order['id'] == 'O-1'
assert len(ml.get_sent()) == 1
updated = svc.update_status('O-1', 'shipped')
assert updated['status'] == 'shipped'
assert len(ml.get_sent()) == 2
"

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS + FAIL)) checks"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
