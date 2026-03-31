# Task

## Source
Synthetic: designed to test repair

## Problem
The file-serving endpoint allows access to files outside the uploads directory. Requesting paths like `/files/../../etc/passwd` returns sensitive system files that should never be exposed. Symlinks within the uploads folder can also be used to escape the intended directory.

## Acceptance Criteria
- [ ] `GET /files/readme.txt` returns HTTP 200 with the file content.
- [ ] `GET /files/../../../etc/passwd` returns HTTP 403 or 400 -- never the file content.
- [ ] `GET /files/subdir/nested.txt` returns HTTP 200 -- nested paths within `uploads/` must still work.
- [ ] All existing tests pass (`pytest tests/`).
- [ ] Symlinks within `uploads/` that point outside the uploads directory must also be rejected (HTTP 403).

## Constraints
- Do not break existing tests
- Max cycles: 15
