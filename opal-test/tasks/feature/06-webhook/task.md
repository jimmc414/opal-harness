# Feature: Webhook Support for Order Management

## Source
Synthetic: designed to test repair, multi-file

## Problem
Add webhook support to the order management system. Users should be able to register webhook URLs and receive POST notifications when an order's status changes.

## Acceptance Criteria

- `POST /webhooks` registers a webhook URL. The request body must contain a `url` field. Returns 201 on success, 400 if the URL is missing.
- `GET /webhooks` returns a list of all registered webhooks.
- `DELETE /webhooks/<id>` removes a registered webhook. Returns 200 or 204 on success.
- When an order's status is updated via `PUT /orders/<id>/status`, all registered webhooks receive a POST notification with the order data as the JSON payload.
- After a webhook is deleted, it must no longer receive notifications on subsequent status changes.

## Constraints
- Do not break existing tests
- Max cycles: 15
