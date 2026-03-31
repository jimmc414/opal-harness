#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

pip install -q pytest 2>/dev/null

# Run full test suite
pytest tests/ -v --tb=short

# Explicitly run the leak-specific tests
pytest tests/test_query.py::test_failed_query_connection_leak -v --tb=short
pytest tests/test_query.py::test_execute_many_partial_failure -v --tb=short
pytest tests/test_query.py::test_pool_exhaustion -v --tb=short
pytest tests/test_query.py::test_double_fault_close -v --tb=short
