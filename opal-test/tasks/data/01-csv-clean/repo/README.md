# CSV Sales Data Cleaner

A pipeline for cleaning and validating messy CSV sales data from external partners.

## Structure

- `data/raw_sales.csv` - Raw input data with known quality issues
- `cleaner/loader.py` - CSV loading utilities
- `cleaner/validator.py` - Row validation and cleaning logic
- `tests/` - Test suite

## Usage

```python
from cleaner.loader import load_csv
from cleaner.validator import clean_dataset

rows = load_csv("data/raw_sales.csv")
clean_rows = clean_dataset(rows)
```
