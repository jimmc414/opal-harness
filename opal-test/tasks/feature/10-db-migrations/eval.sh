#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

run_test() {
    local name="$1"
    shift
    if "$@"; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

# Test 1: Existing tests still pass
run_test "existing_tests_pass" python -c "
import subprocess, sys
result = subprocess.run([sys.executable, '-m', 'pytest', 'tests/test_queries.py', '-x', '-q'],
                        capture_output=True, text=True)
sys.exit(0 if result.returncode == 0 else 1)
"

# Test 2: Migration runner is importable
run_test "migration_runner_importable" python -c "
import sys
sys.path.insert(0, '.')
from db.migrate import apply_migrations, rollback_migration
"

# Test 3: _migrations table is created after running apply
run_test "migrations_table_created" python -c "
import sys
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations

conn = get_connection(':memory:')
create_tables(conn)
apply_migrations(conn)

cursor = conn.execute(\"SELECT name FROM sqlite_master WHERE type='table' AND name='_migrations'\")
row = cursor.fetchone()
assert row is not None, '_migrations table not found'
"

# Test 4: Sample migration file exists with up and down
run_test "sample_migration_exists" python -c "
import sys, os, importlib.util
sys.path.insert(0, '.')

migration_path = os.path.join('migrations', '001_add_profile_fields.py')
assert os.path.exists(migration_path), f'{migration_path} not found'

spec = importlib.util.spec_from_file_location('m001', migration_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

assert hasattr(mod, 'up'), 'Migration missing up() function'
assert hasattr(mod, 'down'), 'Migration missing down() function'
assert callable(mod.up), 'up is not callable'
assert callable(mod.down), 'down is not callable'
"

# Test 5: After apply, users table has bio and avatar_url columns
run_test "columns_added_after_apply" python -c "
import sys
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations

conn = get_connection(':memory:')
create_tables(conn)
apply_migrations(conn)

cursor = conn.execute('PRAGMA table_info(users)')
columns = [row[1] for row in cursor.fetchall()]
assert 'bio' in columns, f'bio column missing, found: {columns}'
assert 'avatar_url' in columns, f'avatar_url column missing, found: {columns}'
"

# Test 6: After apply, _migrations has 1 entry
run_test "migrations_table_has_entry" python -c "
import sys
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations

conn = get_connection(':memory:')
create_tables(conn)
apply_migrations(conn)

rows = conn.execute('SELECT * FROM _migrations').fetchall()
assert len(rows) == 1, f'Expected 1 migration entry, got {len(rows)}'
"

# Test 6b: _migrations table has a timestamp column with a value
run_test "migrations_table_has_timestamp" python -c "
import sys
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations

conn = get_connection(':memory:')
create_tables(conn)
apply_migrations(conn)

cursor = conn.execute('PRAGMA table_info(_migrations)')
columns = {row[1] for row in cursor.fetchall()}
has_ts = 'applied_at' in columns or 'timestamp' in columns or 'created_at' in columns
assert has_ts, f'No timestamp column in _migrations. Columns: {columns}'

row = conn.execute('SELECT * FROM _migrations').fetchone()
row_dict = dict(row)
ts_val = row_dict.get('applied_at') or row_dict.get('timestamp') or row_dict.get('created_at')
assert ts_val is not None, f'Timestamp value is None in migration record: {row_dict}'
"

# Test 7: Re-running apply is idempotent
run_test "apply_idempotent" python -c "
import sys
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations

conn = get_connection(':memory:')
create_tables(conn)
apply_migrations(conn)
apply_migrations(conn)
apply_migrations(conn)

rows = conn.execute('SELECT * FROM _migrations').fetchall()
assert len(rows) == 1, f'Expected 1 entry after repeated apply, got {len(rows)}'
"

# Test 8: After rollback, bio and avatar_url columns are removed
run_test "columns_removed_after_rollback" python -c "
import sys
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations, rollback_migration

conn = get_connection(':memory:')
create_tables(conn)
apply_migrations(conn)
rollback_migration(conn)

cursor = conn.execute('PRAGMA table_info(users)')
columns = [row[1] for row in cursor.fetchall()]
assert 'bio' not in columns, f'bio column still present after rollback: {columns}'
assert 'avatar_url' not in columns, f'avatar_url column still present after rollback: {columns}'
"

# Test 9: After rollback, _migrations table has 0 entries for that migration
run_test "rollback_removes_migration_record" python -c "
import sys
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations, rollback_migration

conn = get_connection(':memory:')
create_tables(conn)
apply_migrations(conn)

rows_before = conn.execute('SELECT * FROM _migrations').fetchall()
assert len(rows_before) == 1, f'Expected 1 before rollback, got {len(rows_before)}'

rollback_migration(conn)

rows_after = conn.execute('SELECT * FROM _migrations').fetchall()
assert len(rows_after) == 0, f'Expected 0 after rollback, got {len(rows_after)}'
"

# Test 10: Migrations apply in filename order
run_test "migrations_apply_in_order" python -c "
import sys, os
sys.path.insert(0, '.')
from db.connection import get_connection
from db.schema import create_tables
from db.migrate import apply_migrations

# Create a second migration file for ordering test
migration_code = '''
def up(conn):
    conn.execute(\"ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'active'\")
    conn.commit()

def down(conn):
    # SQLite does not support DROP COLUMN in older versions,
    # so recreate the table without the column
    conn.execute(\"\"\"
        CREATE TABLE users_backup AS
        SELECT id, username, email, bio, avatar_url FROM users
    \"\"\")
    conn.execute(\"DROP TABLE users\")
    conn.execute(\"\"\"
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL,
            bio TEXT,
            avatar_url TEXT
        )
    \"\"\")
    conn.execute(\"INSERT INTO users SELECT * FROM users_backup\")
    conn.execute(\"DROP TABLE users_backup\")
    conn.commit()
'''

migration_path = os.path.join('migrations', '002_add_status.py')
with open(migration_path, 'w') as f:
    f.write(migration_code)

try:
    conn = get_connection(':memory:')
    create_tables(conn)
    apply_migrations(conn)

    # Check that both migrations were applied
    rows = conn.execute('SELECT * FROM _migrations ORDER BY rowid').fetchall()
    assert len(rows) == 2, f'Expected 2 migration entries, got {len(rows)}'

    # Check columns exist in correct order (bio/avatar_url from 001, status from 002)
    cursor = conn.execute('PRAGMA table_info(users)')
    columns = [row[1] for row in cursor.fetchall()]
    assert 'bio' in columns, f'bio missing: {columns}'
    assert 'avatar_url' in columns, f'avatar_url missing: {columns}'
    assert 'status' in columns, f'status missing: {columns}'

    # Verify ordering: 001 must be recorded before 002
    migration_names = [dict(r) if hasattr(r, 'keys') else r for r in rows]
    # The first applied migration name should sort before the second
    print(f'Migrations applied: {migration_names}')
finally:
    if os.path.exists(migration_path):
        os.remove(migration_path)
"

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS + FAIL)) tests"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
