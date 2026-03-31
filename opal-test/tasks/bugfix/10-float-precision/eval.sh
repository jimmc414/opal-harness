#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

pip install -q pytest 2>/dev/null

# Run entire test suite
pytest tests/ -v --tb=short

# Explicitly verify the critical many-items and formatting tests
pytest tests/test_invoice.py::test_many_items -v --tb=short
pytest tests/test_invoice.py::test_tax_calculation -v --tb=short
pytest tests/test_invoice.py::test_discount_then_tax -v --tb=short
pytest tests/test_invoice.py::test_format_two_decimal_places -v --tb=short
