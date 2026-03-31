# Task

## Source
Synthetic: designed to test direct-solve

## Problem
The `paginator` library provides a `paginate(items, page, per_page)` function documented as 1-indexed (page 1 is the first page). However, requesting page 1 returns the second set of items instead of the first. The first items in the list are unreachable through any valid page number.

## Acceptance Criteria
- [ ] `paginate(items, page=1)` returns the first `per_page` items (items[0:per_page]).
- [ ] No items are duplicated or skipped across consecutive pages — the union of all pages equals the full list.
- [ ] All existing tests pass: `pytest tests/ -x -q` exits 0.
- [ ] `paginate` with `page=0` or a negative page number raises `ValueError`.

## Constraints
- Do not break existing tests
- Max cycles: 15
