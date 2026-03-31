"""Shared fixtures for paginator tests."""

import pytest


@pytest.fixture
def sample_items():
    """A list of 25 items for pagination testing."""
    return list(range(1, 26))


@pytest.fixture
def small_items():
    """A small list of 3 items."""
    return ["a", "b", "c"]
