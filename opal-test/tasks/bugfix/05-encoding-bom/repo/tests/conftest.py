"""Shared test fixtures for fileprocessor tests."""

import os
import pytest


@pytest.fixture
def data_dir():
    """Return the path to the data directory."""
    return os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")


@pytest.fixture
def regular_csv(data_dir):
    """Path to the regular UTF-8 CSV file."""
    return os.path.join(data_dir, "regular.csv")


@pytest.fixture
def bom_csv(data_dir):
    """Path to the UTF-8 BOM CSV file."""
    return os.path.join(data_dir, "bom.csv")
