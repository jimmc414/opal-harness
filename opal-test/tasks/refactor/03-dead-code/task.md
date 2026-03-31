# Remove Dead Code from Math Library

## Source

Synthetic math utility library with accumulated unused code.

## Problem

The `mathlib` package has accumulated dead code over time: an entirely unused `legacy.py` module, unused imports (`os`, `sys`, `json` in `core.py`; `statistics`, `csv` in `stats.py`), unused functions (`deprecated_power`, `_internal_log`, `experimental_factorial` in `core.py`; `variance`, `correlation` in `stats.py`), and a stale import of `deprecated_power` in `stats.py`. This dead code clutters the codebase and obscures the actual public API.

## Acceptance Criteria

- Remove `legacy.py` entirely
- Remove unused imports from `core.py`: `os`, `sys`, `json`
- Remove unused imports from `stats.py`: `statistics`, `csv`, and the `deprecated_power` import
- Remove unused functions from `core.py`: `deprecated_power`, `_internal_log`, `experimental_factorial`
- Remove unused functions from `stats.py`: `variance`, `correlation`
- Any imports that become unused after removing functions must also be removed
- Public API (`__init__.py` exports) remains unchanged
- All existing tests pass
- No new functionality added

## Constraints

- Only remove code, do not add or modify any remaining functions
- Do not change the public API exposed by `__init__.py`
- Do not modify test files
