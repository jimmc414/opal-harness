# document-01-api-docs

## Source

Synthetic task based on a common API documentation generation scenario.

## Problem

A Flask API has several endpoints for CRUD operations on items, but there is no API documentation. The API needs an OpenAPI 3.0 specification file so that consumers can understand the available endpoints, request/response formats, and error codes.

The application has five endpoints: list items, get a single item, create an item, update an item, and delete an item. None of these are currently documented.

## Acceptance Criteria

- An OpenAPI spec file exists at `docs/openapi.yaml` or `docs/openapi.json`
- The spec declares OpenAPI version 3.0.x and has `info` and `paths` sections
- All five endpoints are documented: `GET /api/items`, `GET /api/items/{item_id}`, `POST /api/items`, `PUT /api/items/{item_id}`, `DELETE /api/items/{item_id}`
- Each endpoint includes a description and documents response codes (at least 200/201 and 400/404 where applicable)
- `POST /api/items` documents the request body schema with `name`, `price`, and `category` fields
- The `{item_id}` path parameter is documented with type `integer` in path parameters
- All existing tests pass without modification

## Constraints

- Do not modify the existing application code or tests
- The spec file must be placed in the `docs/` directory
- YAML or JSON format is acceptable
