## Source

Synthetic data ingest pipeline task. A service accepts JSON user records from partner APIs but currently performs no validation, allowing malformed data into the system.

## Problem

The `ingest/schema.py` module contains a stub `validate_record()` function that always returns an empty error list, effectively accepting all records. The pipeline in `ingest/pipeline.py` already calls `validate_record()` and separates accepted from rejected records, but since validation is a no-op, everything is accepted.

Implement `validate_record()` to enforce the data schema and reject invalid records with descriptive error messages.

## Acceptance Criteria

- `validate_record` returns errors for: empty name, missing name, invalid email (must contain @), age less than 0 or greater than 120, missing email, invalid role (only "admin", "user", "editor" are valid roles)
- Valid records have: non-empty `name`, valid `email` (contains @), `age` in range 0-120, `role` in the allowed list
- With the sample data: records 1 (Alice, admin) and 6 (Frank, editor) are accepted; all others are rejected
- Each error message is descriptive (not just "invalid")
- Existing tests still pass
- Record 8 (Hank) is missing the `email` field entirely and must be caught as a missing-email error, not cause a crash

## Constraints

- Do not modify `ingest/pipeline.py`
- Do not modify the sample data file
- Do not add external dependencies beyond the Python standard library
- Preserve the function signature of `validate_record`
