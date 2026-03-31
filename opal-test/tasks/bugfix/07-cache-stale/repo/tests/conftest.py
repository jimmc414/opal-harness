"""Shared test fixtures for productservice tests."""

import pytest
from productservice.service import ProductService
from productservice.cache import SimpleCache


@pytest.fixture
def service():
    """Create a fresh ProductService instance."""
    return ProductService()


@pytest.fixture
def cache():
    """Create a fresh SimpleCache instance."""
    return SimpleCache()
