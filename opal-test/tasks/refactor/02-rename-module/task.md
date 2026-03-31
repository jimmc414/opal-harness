# Rename Utils Module to Formatters

## Source

Synthetic text processing library with a misleadingly-named utility module.

## Problem

The `textproc/utils.py` module only contains string formatting and validation functions (`slugify`, `truncate`, `capitalize_words`, `strip_html`). The name `utils` is vague and does not communicate the module's purpose. It should be renamed to `formatters.py` and all references across the project must be updated.

## Acceptance Criteria

- `textproc/utils.py` renamed to `textproc/formatters.py`
- `textproc/utils.py` no longer exists
- All imports updated: `__init__.py`, `parser.py`, `validator.py`
- Test imports updated to reference `formatters` instead of `utils`
- The package-level re-exports in `textproc/__init__.py` still work (`from textproc import slugify, truncate`)
- All existing tests pass

## Constraints

- Do not change any function signatures or behavior
- Do not add or remove any functions
- Do not rename any functions, only the module file itself
