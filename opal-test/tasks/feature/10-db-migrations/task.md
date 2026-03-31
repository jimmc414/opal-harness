## Source

Internal request to add database migration support to the user management project.

## Problem

The project manages its database schema through a single `create_tables()` call in `db/schema.py`. When the schema needs to change (adding columns, creating new tables, altering constraints), there is no structured way to apply incremental updates or revert them. Changes are applied manually and there is no record of which schema modifications have been made.

The project needs a migration system that can apply incremental schema changes in a controlled, trackable manner and undo them when needed.

## Acceptance Criteria

- The migration runner must be importable as `from db.migrate import apply_migrations, rollback_migration`.
- `apply_migrations(conn)` applies all pending migrations in filename order.
- `rollback_migration(conn)` reverts the most recently applied migration.
- Each migration is a Python file in the `migrations/` directory with `up(conn)` and `down(conn)` functions.
- A `_migrations` table tracks which migrations have been applied, including a timestamp of when each was applied.
- Already-applied migrations are skipped when `apply_migrations` is called again (idempotent).
- A sample migration `001_add_profile_fields.py` is provided that adds `bio TEXT` and `avatar_url TEXT` columns to the `users` table.
- After applying the sample migration, the `bio` and `avatar_url` columns are present and usable in queries.
- Rolling back a migration removes its record from the `_migrations` table.

## Constraints

- Use only the Python standard library and `sqlite3`; do not add external dependencies.
- Do not modify the existing `db/queries.py` or `db/schema.py` files.
- Do not alter the existing test suite.
- Migration files must be regular Python files importable from the `migrations/` directory.
