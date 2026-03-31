## Source

Internal request to secure the Items API with role-based access control.

## Problem

The Items API currently allows unrestricted access to all endpoints. Any caller can create, read, update, or delete items without authentication. The application needs role-based access control so that different user roles have different permissions.

An authentication module (`app/auth.py`) already exists with a `get_user_from_token` function that maps bearer tokens to user records containing a `role` field. The three roles in the system are `admin`, `editor`, and `viewer`. However, none of the route handlers currently use this module or enforce any access restrictions.

## Acceptance Criteria

- All endpoints require authentication via an `Authorization: Bearer <token>` header.
- Requests without a valid token receive a `401` status code.
- Requests with a valid token but insufficient role privileges receive a `403` status code with the response body `{"error": "forbidden"}`.
- **Viewer** role: can access `GET /items` and `GET /items/<id>`, but cannot create, update, or delete items.
- **Editor** role: can access `GET /items`, `GET /items/<id>`, `POST /items`, and `PUT /items/<id>`, but cannot delete items.
- **Admin** role: can perform all operations, including `DELETE /items/<id>`.
- `GET /items` and `GET /items/<id>` must remain accessible to all three authenticated roles, not just admin.

## Constraints

- Use the existing `app/auth.py` module for token-to-user resolution; do not replace or duplicate the user store.
- Do not add external dependencies beyond Flask (already installed).
- Do not change the URL structure or HTTP methods of existing endpoints.
- Existing item CRUD logic (validation, 404 handling, response format) must remain unchanged for authorized requests.
