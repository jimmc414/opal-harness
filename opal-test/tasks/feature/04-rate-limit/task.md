# Feature: Rate Limiting

## Source
Synthetic: designed to test direct-solve

## Problem
The API needs rate limiting to prevent abuse. Add in-memory rate limiting that restricts each client IP address to a maximum of 5 requests per minute across all endpoints.

When the limit is exceeded, the API should return HTTP 429 with a JSON body of `{"error": "rate limit exceeded"}`.

## Acceptance Criteria

- The first 5 requests from a client within a 60-second window succeed normally
- The 6th request within that window returns 429 with `{"error": "rate limit exceeded"}`
- Different client IP addresses have independent rate limits
- After the time window expires, requests are allowed again
- Rate limiting applies to all endpoints

## Constraints
- Do not break existing tests
- Max cycles: 15
