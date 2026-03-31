"""Shared fixtures for scheduler tests."""

import os
import pytest
from datetime import datetime


@pytest.fixture(autouse=True)
def _ensure_eastern_tz(monkeypatch):
    """Force America/New_York for every test so DST behaviour is exercised."""
    monkeypatch.setenv("TZ", "America/New_York")
    # Re-initialize the C library's timezone data after changing TZ.
    import time as _time
    _time.tzset()
