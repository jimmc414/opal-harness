# Feature: Health Check Endpoint

## Source
Synthetic: designed to test direct-solve

## Problem
The API needs a health check endpoint for monitoring and load balancer probes.

Add a `GET /health` endpoint that returns a JSON response indicating the service is healthy.

## Acceptance Criteria

- `GET /health` returns HTTP 200
- Response body is `{"status": "healthy"}`
- Response Content-Type is `application/json`
- All existing endpoints continue to work as before
- `POST /health` must return 405 (Method Not Allowed)

## Constraints
- Do not break existing tests
- Max cycles: 15
