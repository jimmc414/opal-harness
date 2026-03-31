# Feature: Exponential Backoff Retry Logic

## Source
Synthetic: designed to test repair

## Problem
Add exponential backoff retry logic to the API client's `fetch()` method.

## Acceptance Criteria

- On 5xx HTTP errors, the `fetch()` method retries up to 3 total attempts before returning the error response.
- On 4xx HTTP errors, the `fetch()` method must NOT retry and must return the error immediately.
- If a retry attempt succeeds, `fetch()` returns the successful response.
- Backoff delays double with each retry attempt (e.g., base delay, then 2x base delay).
- 503 Service Unavailable must be retried just like 500 Internal Server Error.

## Constraints
- Do not break existing tests
- Max cycles: 15
