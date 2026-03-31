## Source

Synthetic Flask API with breaking changes between v1 and v2.

## Problem

A Flask application has both v1 and v2 API implementations side by side. The v2 API introduces several breaking changes from v1: renamed endpoints, changed request/response formats, different HTTP methods, and restructured error responses. There is no migration guide to help API consumers upgrade from v1 to v2.

Analyze the differences between `api/v1.py` and `api/v2.py` and write a comprehensive migration guide that documents every breaking change with clear before/after examples.

## Acceptance Criteria

- A migration guide file exists at `docs/migration-guide.md`
- Guide has a title and overview section
- Documents the URL path change (`/items` to `/products`)
- Documents the request field renames (`name` to `title`, `price` to `cost`, `category` to `type`)
- Documents the response format changes (`data` wrapper to `product`/`products`, `count` to `total`)
- Documents the HTTP method change (`PUT` to `PATCH` for updates)
- Documents the error format change (plain string to structured object with `code` and `message`)
- Documents the status code changes (`400` to `422` for validation errors, `200` to `204` for delete)
- Includes code examples showing before/after for at least 2 operations
- The guide must mention the `item_id` to `product_id` URL parameter rename
- Existing tests still pass

## Constraints

- Do not modify any existing source files
- The guide must be placed at `docs/migration-guide.md` (create the `docs/` directory)
- The guide must be written in Markdown format
- All documented changes must be accurate to the actual code differences
