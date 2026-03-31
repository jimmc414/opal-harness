# Task

## Source
Synthetic: designed to test repair

## Problem
After updating a product's data, fetching the same product returns the old values. The stale data persists until the application is restarted.

## Acceptance Criteria
- [ ] After `update_product`, subsequent `get_product` returns the updated data.
- [ ] Cache is properly invalidated or updated on writes.
- [ ] All existing tests pass (`pytest tests/ -v` exits 0).
- [ ] `list_products` must also reflect updates immediately (not cached, but verify it still works correctly after cache changes).

## Constraints
- Do not break existing tests
- Max cycles: 15
