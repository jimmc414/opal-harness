# productservice

A product data access layer with in-memory caching for fast reads.

## Features

- In-memory cache with get/set/invalidate/clear operations
- Mock database backend for product storage
- Service layer composing cache and database for transparent caching
- List all products from the database

## Usage

```python
from productservice.service import ProductService

service = ProductService()
product = service.get_product("p1")  # Fetches from DB, caches result
product = service.get_product("p1")  # Returns cached result

service.update_product("p1", {"price": 29.99})
product = service.get_product("p1")  # Should reflect update

all_products = service.list_products()
```

## Project Structure

```
productservice/
    __init__.py
    cache.py        # SimpleCache implementation
    db.py           # Mock ProductDB database
    service.py      # ProductService composing cache + db
tests/
    conftest.py
    test_cache.py   # Cache unit tests
    test_service.py # Service integration tests
```

## Running Tests

```bash
pytest tests/ -v
```
