# Task

## Source
Synthetic: designed to test direct-solve

## Problem
The user profile API is a Flask application that serves user data. The `GET /users/<id>` endpoint returns a 500 Internal Server Error for certain users. The endpoint works fine for most users, but crashes when fetching users who do not have an email address on file. The `GET /users/` listing endpoint also fails if any such user exists in the database.

## Acceptance Criteria
- [ ] `GET /users/<id>` returns HTTP 200 for users with null email (email field should be `null` in the JSON response).
- [ ] `GET /users/` returns all users without error, even when some have null email.
- [ ] All existing tests pass: `pytest tests/ -x -q` exits 0.
- [ ] The response must use JSON `null` for missing email, NOT an empty string `""`. This is a contract requirement.

## Constraints
- Do not break existing tests
- Max cycles: 15
