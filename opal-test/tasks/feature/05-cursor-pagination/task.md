# Feature: Cursor-Based Pagination

## Source
Synthetic: designed to test repair

## Problem
Replace the current offset-based pagination (`?page=&per_page=`) with cursor-based pagination.

The `/items` endpoint currently accepts `page` and `per_page` query parameters for offset pagination. Convert this to cursor-based pagination.

## Acceptance Criteria

- The response must include `items` (list of items) and `next_cursor` (a base64-encoded cursor string for fetching the next page).
- The endpoint must accept a `?cursor=` query parameter to fetch subsequent pages.
- The `?per_page=` parameter must still control page size (default 10).
- The last page must have `next_cursor` set to `null`.
- Walking through all pages using cursors must yield all items with no duplicates and no missing entries.

## Constraints
- Do not break existing tests
- Max cycles: 15
