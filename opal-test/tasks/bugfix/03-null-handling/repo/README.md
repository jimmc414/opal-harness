# User Profile API

A simple Flask API for managing user profiles.

## Endpoints

- `GET /users/` — List all users
- `GET /users/<id>` — Get a single user by ID

## Setup

```bash
pip install flask pytest
```

## Running

```bash
flask --app app.routes:create_app run
```

## Running Tests

```bash
pytest tests/ -x -q
```
