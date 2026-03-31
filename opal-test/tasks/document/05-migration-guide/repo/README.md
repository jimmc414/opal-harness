# Item Management API

A Flask-based REST API for managing items/products.

## Structure

- `api/v1.py` - Version 1 API routes
- `api/v2.py` - Version 2 API routes
- `models/items.py` - Shared data model

## Running

```bash
pip install flask
python3 -c "from api import create_app; create_app().run()"
```

## Running Tests

```bash
pip install flask pytest
python3 -m pytest tests/ -v
```
