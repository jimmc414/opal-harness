## Source

Synthetic -- Flask application environment configuration scenario.

## Problem

A Flask application has all configuration values hardcoded in `app/__init__.py`. The application needs environment-specific configuration files for development, staging, and production so that the same codebase can run with different settings in each environment. Currently there is no way to switch between environments.

## Acceptance Criteria

- Environment-specific config files exist: `config/development.py`, `config/staging.py`, `config/production.py`
- `create_app(env)` loads config based on the `env` parameter (or `APP_ENV` environment variable)
- Development: `DEBUG=True`, `LOG_LEVEL='DEBUG'`, sqlite database
- Staging: `DEBUG=False`, `LOG_LEVEL='WARNING'`
- Production: `DEBUG=False`, `LOG_LEVEL='ERROR'`
- Production `SECRET_KEY` must not be a hardcoded string -- it should read from an environment variable or raise an error if not set
- Default environment (no env specified) uses development config
- Existing tests still pass

## Constraints

- Do not change the route handlers or models
- Do not add new Python dependencies beyond the standard library and Flask
- Config files should be importable Python modules
