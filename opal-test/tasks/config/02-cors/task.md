# config-02-cors

## Source

Synthetic task based on a common cross-origin resource sharing configuration scenario.

## Problem

A Flask API serves data at `/api/items` but has no CORS headers configured. A frontend application running at `http://localhost:3000` cannot call the API due to browser cross-origin restrictions. The API needs proper CORS support including preflight handling for non-simple requests.

## Acceptance Criteria

- `GET /api/items` response includes the `Access-Control-Allow-Origin` header
- The allowed origin is specifically `http://localhost:3000` (not a wildcard `*`)
- `OPTIONS /api/items` preflight request returns HTTP 200 with correct CORS headers
- Preflight response includes `Access-Control-Allow-Methods` with at least `GET` and `POST`
- Preflight response includes `Access-Control-Allow-Headers` with `Content-Type`
- CORS headers appear on actual responses (GET, POST), not only on preflight
- All existing API tests pass without modification

## Constraints

- Do not modify the existing test files
- The CORS origin must be `http://localhost:3000` specifically, not `*`
- The solution may use `flask-cors` or manual header injection
