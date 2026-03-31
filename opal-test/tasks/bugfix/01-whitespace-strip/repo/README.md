# csvlib

A lightweight CSV parsing library for Python.

## Usage

```python
from csvlib.parser import parse_csv
from csvlib.transforms import filter_rows, sort_rows

rows = parse_csv("data/sample.csv")
# rows is a list of dicts, e.g. [{"id": "1", "name": "Alice", ...}, ...]

adults = filter_rows(rows, "age", lambda x: int(x) >= 18)
sorted_rows = sort_rows(rows, "name")
```

## Running Tests

```bash
pytest tests/ -x -q
```
