# Data Ingest Pipeline

A JSON record ingest pipeline with schema validation for user records.

## Structure

- `ingest/pipeline.py` - Main ingest pipeline with accept/reject logic
- `ingest/schema.py` - Record validation logic
- `data/sample_records.json` - Sample input records for testing
- `tests/` - Test suite

## Usage

```python
import json
from ingest.pipeline import ingest

with open("data/sample_records.json") as f:
    records = json.load(f)

result = ingest(records)
print(f"Accepted: {len(result['accepted'])}")
print(f"Rejected: {len(result['rejected'])}")
```
