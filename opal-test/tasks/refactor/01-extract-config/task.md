# Extract Hardcoded Configuration Values

## Source

Synthetic Flask application with configuration values scattered as literals across multiple source files.

## Problem

The Flask application has hardcoded configuration values (database URL, secret key, API timeout, max retries, page size, pool size) scattered across `app/__init__.py`, `app/database.py`, `app/api_client.py`, and `app/routes.py`. This makes it difficult to change settings across environments and violates the single-source-of-truth principle.

## Acceptance Criteria

- All hardcoded values extracted to a single `app/config.py` module
- `config.py` contains: `DB_URL`, `DB_POOL_SIZE`, `SECRET_KEY`, `API_TIMEOUT`, `API_MAX_RETRIES`, `PAGE_SIZE`
- All source files import from `app.config` instead of using literals
- No hardcoded string `"postgresql://localhost:5432/myapp"` remains in `database.py`
- No hardcoded `'dev-secret-key-123'` remains in `__init__.py`
- No hardcoded `page_size = 20` literal assignment remains in `routes.py`
- `api_client.py` must also use config values, not local literals
- All existing tests pass with identical behavior

## Constraints

- Do not change the public interface of any function or class
- Do not modify test files
- The new `config.py` must use module-level constants (not a class or dict)
