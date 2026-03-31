# Task: Environment Variable Config Override Is Inconsistent

## Source
Synthetic: designed to test pause, checkpoint

## Problem

The application loads configuration from multiple sources with the intended
precedence: defaults < config file < environment variables < CLI arguments.

Users report that environment variable overrides work inconsistently:

- Setting `APP_LOG_LEVEL`, `APP_DB_HOST`, and `APP_WORKERS` via environment
  variables correctly overrides values from a config file.
- Setting `APP_PORT` and `APP_DEBUG` via environment variables has **no effect**
  when a config file is also provided. The config file values always win for
  those two settings.

For example, running with `APP_PORT=9999` and a config file containing
`"port": 3000` results in port being `3000` instead of the expected `9999`.

## Acceptance Criteria

1. All five environment variables (`APP_PORT`, `APP_DEBUG`, `APP_LOG_LEVEL`,
   `APP_DB_HOST`, `APP_WORKERS`) consistently override config file values.
2. CLI arguments still override everything, including environment variables.
3. When no config file or env vars are set, defaults are used.
4. All existing tests pass.

## Constraints
- Do not break existing tests
- Max cycles: 15
