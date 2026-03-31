## Source

Synthetic ETL pipeline with type coercion bugs.

## Problem

An ETL (Extract-Transform-Load) pipeline processes product records from a JSON source file. The `transform()` function in `etl/transform.py` silently drops any record that causes a `TypeError` or `ValueError` during type conversion. This means records with string-encoded numbers (e.g., `"24.99"` for price, `"5"` for quantity) are discarded even though they could be coerced to the correct types. Additionally, records with genuinely invalid data (null prices, non-numeric quantities, empty names, negative quantities) are silently dropped with no error tracking, making data loss invisible.

The pipeline needs to be fixed so that:
1. Coercible values are properly converted (string numbers, string booleans).
2. Records that cannot be fixed are rejected with tracked error information.
3. The caller can see both successfully transformed records and rejected records with reasons.

## Acceptance Criteria

- `transform()` coerces string numbers to correct types (record 2: `"24.99"` to `24.99`, `"5"` to `5`; record 4: `"4"` to `4`)
- `transform()` coerces string booleans (`"yes"`/`"no"` to `True`/`False`)
- Records with `null`/`None` price are rejected with an error entry (record 5)
- Records with unconvertible values are rejected with an error entry (record 6: `"twelve"` for quantity)
- Records with empty name are rejected with an error entry (record 7)
- Records with negative quantity are rejected with an error entry (record 8)
- `transform()` returns a tuple of `(transformed_records, error_records)` or the errors are tracked via the store
- After full ETL on `source.json`: exactly 4 records loaded (ids 1, 2, 3, 4), exactly 4 rejected (ids 5, 6, 7, 8)
- Existing tests still pass
- Record 4 has id as string `"4"` in the source data -- it must be coerced to int `4`, not rejected

## Constraints

- Do not modify `data/source.json`
- Do not modify `etl/extract.py`
- The `TargetStore` class in `etl/load.py` already has an `add_error()` method that can be used for error tracking
- All changes should be backward-compatible with existing test assertions
- Use only the Python standard library
