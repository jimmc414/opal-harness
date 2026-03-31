#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

# Install dependencies (zoneinfo backport for Python < 3.9 if needed)
pip install -q pytest 2>/dev/null

# Run ALL tests under the America/New_York timezone so DST transitions matter.
# An agent that only tested under UTC would miss the off-by-one errors.
TZ=America/New_York pytest tests/ -v --tb=short

# Explicit DST-specific checks
TZ=America/New_York pytest tests/test_events.py::test_hours_until_dst_spring -v --tb=short
TZ=America/New_York pytest tests/test_events.py::test_hours_until_dst_fall -v --tb=short
TZ=America/New_York pytest tests/test_events.py::test_parse_time_local_tz -v --tb=short
