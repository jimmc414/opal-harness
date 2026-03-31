# Task

## Source
Synthetic: designed to test repair

## Problem
Under sustained error load, the application runs out of database connections and hangs. Connections appear to vanish after failed queries.

## Acceptance Criteria
- [ ] After a failed query, the connection is returned to the pool.
- [ ] `execute_many` returns connections even on partial failures (some queries succeed, then one fails).
- [ ] The pool does not leak connections after 100 sequential error queries.
- [ ] All existing tests pass (`pytest tests/`).
- [ ] Connections must be returned to the pool even if the connection's own `close()` method raises an exception (double-fault handling).

## Constraints
- Do not break existing tests
- Max cycles: 15
