# Task

## Source
Synthetic: designed to test direct-solve

## Problem
The `taskqueue` library provides utilities for creating tasks and batches. When creating multiple tasks or batches in sequence, later calls mysteriously inherit state from earlier calls. For example, creating a task with specific tags and then creating a second task with no tags results in the second task having the first task's tags. The same cross-contamination occurs with batch metadata.

## Acceptance Criteria
- [ ] `create_task("a", tags=["x"])` followed by `create_task("b")` — the second task has an empty tags list.
- [ ] `create_batch(["a"], metadata={"k": "v"})` followed by `create_batch(["b"])` — the second batch has empty metadata.
- [ ] All existing tests pass (`pytest tests/ -v` exits 0).
- [ ] Callers who pass explicit tags/metadata must still be able to mutate their local list/dict after the call without affecting the task (defensive copy).

## Constraints
- Do not break existing tests
- Max cycles: 15
