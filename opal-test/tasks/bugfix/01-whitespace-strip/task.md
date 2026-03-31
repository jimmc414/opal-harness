# Task

## Source
Synthetic: designed to test direct-solve

## Problem
The `csvlib` CSV parsing library reads CSV files and returns data as a list of dictionaries. Users report that accessing fields by column name raises `KeyError` even though the column clearly exists in the CSV file. The issue occurs with certain CSV files but not others.

## Acceptance Criteria
- [ ] `parse_csv` returns dicts with stripped header keys (no leading/trailing whitespace in any key).
- [ ] All existing tests pass: `pytest tests/ -x -q` exits 0.
- [ ] The fix handles headers with tabs and mixed whitespace (e.g., `"\t name \t"`), not just spaces.
- [ ] `parse_csv` still works correctly with `data/clean.csv` — a file that has no whitespace issues in its headers. This must not regress.

## Constraints
- Do not break existing tests
- Max cycles: 15
