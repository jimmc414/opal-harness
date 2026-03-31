# paginator

A simple Python pagination utility.

## Usage

```python
from paginator.core import paginate, total_pages

items = list(range(1, 101))  # 100 items

result = paginate(items, page=1, per_page=10)
print(result.items)        # first 10 items
print(result.page)         # 1
print(result.total_pages)  # 10
print(result.total_items)  # 100

tp = total_pages(items, per_page=10)  # 10
```

Pages are **1-indexed**: page 1 is the first page.

## Running Tests

```bash
pytest tests/ -x -q
```
