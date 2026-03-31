# Task

## Source
Synthetic: designed to test direct-solve

## Problem
A Python project with three modules fails to start. Attempting to import any of the application's modules results in an `ImportError`. Running `python -c "from app import models"` crashes immediately.

## Acceptance Criteria
- [ ] `python -c "from app import models"` succeeds without ImportError.
- [ ] `python -c "from app import validators"` succeeds without ImportError.
- [ ] `python -c "from app import helpers"` succeeds without ImportError.
- [ ] All existing tests pass: `pytest tests/ -x -q` exits 0.
- [ ] No function signatures or return types are changed. The fix must not alter the public API of any module. All public functions must remain importable from their original modules.

## Constraints
- Do not break existing tests
- Max cycles: 15
