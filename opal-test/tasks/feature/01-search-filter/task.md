# Feature: Search Filter for Items Endpoint

## Source
Synthetic: designed to test direct-solve

## Problem
Users want to filter items by keyword. The `/items` endpoint should accept an optional `?q=keyword` query parameter that filters items whose name or description contains the keyword as a case-insensitive substring match.

Without the `?q` parameter, or with an empty `?q=`, the endpoint should return all items as it does today.

## Acceptance Criteria

- `GET /items?q=mouse` returns only items where "mouse" appears in the name or description (case-insensitive)
- `GET /items?q=KEYBOARD` returns matching items regardless of case
- `GET /items?q=nonexistent` returns an empty list
- `GET /items` (no query parameter) returns all items
- `GET /items?q=` (empty string) returns all items
- Existing behavior and response format are preserved

## Constraints
- Do not break existing tests
- Max cycles: 15
