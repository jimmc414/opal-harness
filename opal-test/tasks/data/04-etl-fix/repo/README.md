# ETL Pipeline

A simple Extract-Transform-Load pipeline for processing product records.

## Structure

- `etl/extract.py` - Reads records from JSON source files
- `etl/transform.py` - Transforms records to target schema
- `etl/load.py` - Loads records into a target store
- `data/source.json` - Source data file

## Usage

```python
from etl.extract import extract
from etl.transform import transform
from etl.load import TargetStore, load

records = extract("data/source.json")
transformed = transform(records)
store = TargetStore()
load(store, transformed)
```

## Running Tests

```bash
python3 -m pytest tests/ -v
```
