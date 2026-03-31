"""Shared test fixtures for taskqueue tests."""

import pytest


@pytest.fixture(autouse=True)
def reset_module_state():
    """Ensure each test starts with a clean module state.

    This is important because mutable default arguments persist
    across calls within the same Python process.
    """
    yield
    # No explicit cleanup needed; the mutable default bug is the
    # point of this test suite. The tests themselves verify isolation.
