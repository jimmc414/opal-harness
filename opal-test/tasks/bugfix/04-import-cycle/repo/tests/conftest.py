"""Shared fixtures for app tests."""

import pytest


@pytest.fixture
def sample_user():
    """A valid User instance for testing."""
    from app.models import User
    return User(name="Alice", email="alice@example.com")


@pytest.fixture
def sample_order(sample_user):
    """A valid Order instance for testing."""
    from app.models import Order
    return Order(user=sample_user, item="Widget", quantity=2, price_cents=1500)
