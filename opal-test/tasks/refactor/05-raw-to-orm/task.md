# Replace Raw SQL with Model-Based Queries

## Source

Synthetic task tracker with inline SQL and an unused ORM-style base class.

## Problem

The `tracker/database.py` module contains CRUD functions that use raw SQL strings for all operations. A `Model` base class already exists in `tracker/models.py` but is not used. The database functions should be refactored to use the Model abstraction, with a `Task` model class handling persistence. The `search_tasks` function requires special attention since the base `Model` class has no built-in search capability.

## Acceptance Criteria

- Create a `Task` model class in `models.py` extending `Model` with `_table = "tasks"` and appropriate `_fields`
- Refactor `database.py` functions to use the `Task` model instead of raw SQL
- All functions still return plain dicts (not model instances)
- `search_tasks` must still work correctly
- All existing tests pass with no changes to test code
- No raw SQL strings remain in `database.py` CRUD functions (table creation in `get_db` is exempt)
- The `update_task` function with no valid update fields returns the existing task unchanged

## Constraints

- Do not modify test files
- Do not change the function signatures in `database.py`
- The `get_db` function may still contain the CREATE TABLE statement
- Return types must remain plain dicts, not model instances
