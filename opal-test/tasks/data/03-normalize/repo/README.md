# Order Database Normalizer

A tool for normalizing a denormalized order database into proper relational tables.

## Structure

- `database/setup.py` - Creates the denormalized orders table and seeds test data
- `database/queries.py` - Query functions for the flat orders table
- `database/normalize.py` - Normalization logic (to be implemented)
- `tests/` - Test suite

## Usage

```python
from database.setup import create_db
from database.normalize import normalize

conn = create_db("orders.db")
normalize(conn)
```
