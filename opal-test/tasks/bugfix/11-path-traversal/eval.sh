#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

pip install -q pytest flask 2>/dev/null

# Run full test suite
pytest tests/ -v --tb=short

# Explicitly run the security-critical tests
pytest tests/test_app.py::test_path_traversal -v --tb=short
pytest tests/test_app.py::test_path_traversal_encoded -v --tb=short
pytest tests/test_app.py::test_symlink_escape -v --tb=short
pytest tests/test_app.py::test_serve_nested_file -v --tb=short
