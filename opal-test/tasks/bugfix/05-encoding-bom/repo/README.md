# fileprocessor

A Python module for reading and analyzing CSV data files.

## Features

- Read CSV files into structured row dictionaries
- Analyze and summarize column statistics (min, max, mean for numeric columns)
- Supports standard CSV format with headers

## Usage

```python
from fileprocessor.reader import read_csv
from fileprocessor.analyzer import summarize

rows = read_csv("data/regular.csv")
stats = summarize(rows)
print(stats)
```

## Project Structure

```
fileprocessor/
    __init__.py
    reader.py       # CSV reading utilities
    analyzer.py     # Data analysis and summarization
data/
    regular.csv     # Sample UTF-8 CSV file
    bom.csv         # Sample UTF-8 BOM CSV file
tests/
    conftest.py
    test_reader.py
```

## Running Tests

```bash
pytest tests/ -v
```
