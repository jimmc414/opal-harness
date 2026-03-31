"""Shared fixtures for csvlib tests."""

import os
import pytest


@pytest.fixture
def sample_csv_path():
    """Path to the sample CSV with whitespace in headers."""
    return os.path.join(os.path.dirname(__file__), "..", "data", "sample.csv")


@pytest.fixture
def clean_csv_path():
    """Path to the clean CSV without whitespace issues."""
    return os.path.join(os.path.dirname(__file__), "..", "data", "clean.csv")
