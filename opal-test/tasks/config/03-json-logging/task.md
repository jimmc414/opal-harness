# config-03-json-logging

## Source

Synthetic task based on a common observability and logging configuration scenario.

## Problem

A Flask application uses Python's built-in `logging` module with a plain text format (`%(asctime)s - %(name)s - %(levelname)s - %(message)s`). For production deployment, the logging output needs to be structured JSON so that log aggregation tools (ELK, Datadog, etc.) can parse and index log entries.

The current setup in `app/__init__.py` uses `logging.basicConfig` with a text formatter. This needs to be replaced with a JSON logging configuration.

## Acceptance Criteria

- Log output is valid JSON (one JSON object per log line)
- Each log entry contains at least these fields: `timestamp`, `level`, `message`
- The `level` field uses standard Python level names (`INFO`, `WARNING`, `ERROR`)
- The `timestamp` field is in ISO 8601 format
- Logging works correctly for all log levels (info, warning, error)
- The JSON formatter handles log messages containing special characters (quotes, newlines) without producing invalid JSON
- All existing application tests pass without modification

## Constraints

- Do not modify the existing test files
- Do not modify `app/routes.py` or `app/models.py`
- The solution should use Python standard library or commonly available packages
