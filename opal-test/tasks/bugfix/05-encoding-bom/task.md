# Task

## Source
Synthetic: designed to test direct-solve

## Problem
The `fileprocessor` module reads CSV files using `csv.DictReader`. It works correctly for most CSV files, but CSV files exported from certain sources (e.g., Excel, some Windows tools) cause the parser to fail. When these files are loaded, the first header comes back with garbage characters prepended to it, causing key lookup failures and data inconsistencies downstream.

## Acceptance Criteria
- [ ] `read_csv` works correctly on both regular CSV files and CSV files from problematic sources.
- [ ] Headers are clean regardless of the file's origin — no unexpected characters prepended to any header.
- [ ] All existing tests pass (`pytest tests/ -v` exits 0).
- [ ] The fix must not corrupt files that are read — files without the issue must still produce correct results (no data loss, no altered headers).

## Constraints
- Do not break existing tests
- Max cycles: 15
