## Source

Synthetic CSV data processing task. A sales data pipeline receives messy CSV files from external partners with inconsistent date formats, missing fields, and type errors.

## Problem

The `cleaner/validator.py` module contains stub functions `validate_row()` and `clean_dataset()` that currently return all rows unchanged. The CSV file `data/raw_sales.csv` contains 8 rows with various data quality issues: inconsistent date formats (ISO, DD/MM/YYYY, written), missing values, non-numeric amounts, and empty fields.

Implement the validation and cleaning logic so that the pipeline produces only clean, valid records.

## Acceptance Criteria

- `clean_dataset()` normalizes all date formats to `YYYY-MM-DD`
- Rows with missing `amount` are skipped (row 3)
- Rows with non-numeric `amount` are skipped (row 5)
- Rows with missing `customer` are skipped (row 6)
- `amount` values are converted to `float`
- Rows with missing `date` are skipped (row 7)
- Rows with missing `region` get region set to `"Unknown"` (row 8: missing region should not cause skip, just default)
- After cleaning, all remaining rows have valid dates, numeric amounts, and non-empty customer names
- Existing tests still pass

## Constraints

- Do not modify the CSV file
- Do not modify `cleaner/loader.py`
- Do not add external dependencies beyond the Python standard library
- Preserve the function signatures of `validate_row` and `clean_dataset`
