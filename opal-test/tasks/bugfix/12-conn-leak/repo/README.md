# Database

A lightweight database access layer with connection pooling.

## Usage

```python
from database.pool import ConnectionPool
from database.connection import MockConnection
from database.query import execute_query

pool = ConnectionPool(max_size=5, connection_factory=MockConnection)
results = execute_query(pool, "SELECT * FROM users WHERE id = ?", params=(42,))
```

## Modules

| Module | Purpose |
|--------|---------|
| `database.pool` | `ConnectionPool` — thread-safe pool with semaphore |
| `database.connection` | `MockConnection` — simulated DB connection |
| `database.query` | `execute_query`, `execute_many` — query execution helpers |
| `database.migrations` | `run_migrations` — sequential migration runner |

## Running Tests

```bash
pytest tests/ -v
```
