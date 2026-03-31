# Feature: CSV Export for Reports

## Source
Synthetic: designed to test direct-solve

## Problem
The reporting module needs CSV export capability. Add a `format_csv` function that converts a Report into CSV format with a header row followed by data rows.

The function should be importable via `from reports.formatters import format_csv` and accept a Report object as its argument, returning a CSV-formatted string.

## Acceptance Criteria

- `from reports.formatters import format_csv` works without ImportError
- Output starts with a header row containing the report's column names
- Data rows follow with values in the same column order
- Commas within data values are handled correctly (proper CSV quoting)
- Double quotes within data values are handled correctly (proper CSV escaping)
- Existing `format_text` and `format_json` functions continue to work

## Constraints
- Do not break existing tests
- Max cycles: 15
