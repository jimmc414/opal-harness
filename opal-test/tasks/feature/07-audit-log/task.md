# Feature: Audit Logging

## Source
Synthetic: designed to test repair, multi-file

## Problem
Add audit logging for all write operations (create, update, delete) on items, with a queryable endpoint.

## Acceptance Criteria

- All write operations (POST, PUT, DELETE on `/items`) must create an audit log entry.
- Each audit entry must contain: `action` (one of "create", "update", "delete"), `resource_type`, `resource_id`, and `timestamp` (ISO 8601 format).
- `GET /audit-log` returns a list of all audit entries in chronological order.
- Read operations (`GET /items`, `GET /items/<id>`) must NOT create audit entries.
- The audit log starts empty and grows as write operations occur.

## Constraints
- Do not break existing tests
- Max cycles: 15
