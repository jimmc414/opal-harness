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

# 2. Task class exists in models.py with correct _table
check "Task class exists with _table = tasks" python -c "
from tracker.models import Task
assert Task._table == 'tasks'
assert 'id' in Task._fields
assert 'title' in Task._fields
assert 'status' in Task._fields
"

# 3. No raw SQL in database.py CRUD functions (excluding get_db which has CREATE TABLE)
# grep in database.py for raw SQL patterns - these only appear in CRUD code, not in get_db
check_not "No INSERT INTO in database.py" grep -q 'INSERT INTO' tracker/database.py
check_not "No DELETE FROM in database.py" grep -q 'DELETE FROM' tracker/database.py
check_not "No SELECT.*FROM tasks in database.py" grep -qE 'SELECT \* FROM tasks' tracker/database.py
check_not "No raw UPDATE SET in database.py" grep -qE 'UPDATE.*SET' tracker/database.py

# 4. Functions still return dicts not model objects
check "create_task returns dict" python -c "
from tracker.database import get_db, create_task
conn = get_db()
result = create_task(conn, 'Test')
assert type(result) is dict, f'Expected dict, got {type(result)}'
conn.close()
"

check "get_task returns dict" python -c "
from tracker.database import get_db, create_task, get_task
conn = get_db()
t = create_task(conn, 'Test')
result = get_task(conn, t['id'])
assert type(result) is dict, f'Expected dict, got {type(result)}'
conn.close()
"

check "get_all_tasks returns list of dicts" python -c "
from tracker.database import get_db, create_task, get_all_tasks
conn = get_db()
create_task(conn, 'Test')
results = get_all_tasks(conn)
assert type(results) is list
assert type(results[0]) is dict
conn.close()
"

# 5. search_tasks still works correctly
check "search_tasks by title" python -c "
from tracker.database import get_db, create_task, search_tasks
conn = get_db()
create_task(conn, 'Buy groceries', 'Milk, eggs')
create_task(conn, 'Fix bug', 'NullPointer')
results = search_tasks(conn, 'groceries')
assert len(results) == 1
assert results[0]['title'] == 'Buy groceries'
conn.close()
"

check "search_tasks by description" python -c "
from tracker.database import get_db, create_task, search_tasks
conn = get_db()
create_task(conn, 'Fix bug', 'NullPointerException in parser')
results = search_tasks(conn, 'parser')
assert len(results) == 1
conn.close()
"

# 6. Edge case: update_task with no valid fields returns existing task
check "update_task with no valid fields returns existing task" python -c "
from tracker.database import get_db, create_task, update_task
conn = get_db()
task = create_task(conn, 'Original')
result = update_task(conn, task['id'], invalid_field='value')
assert result['title'] == 'Original'
conn.close()
"

# 7. Edge case: operations on missing tasks return None
check "get_task returns None for missing" python -c "
from tracker.database import get_db, get_task
conn = get_db()
assert get_task(conn, 999) is None
conn.close()
"

check "delete_task returns None for missing" python -c "
from tracker.database import get_db, delete_task
conn = get_db()
assert delete_task(conn, 999) is None
conn.close()
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
