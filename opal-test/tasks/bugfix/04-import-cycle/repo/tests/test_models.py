"""Tests for app.models."""

from app.models import User, Order


def test_user_creation():
    """User should store name and email."""
    u = User(name="Alice", email="alice@example.com")
    assert u.name == "Alice"
    assert u.email == "alice@example.com"


def test_user_is_valid():
    """User.is_valid should return True for valid emails."""
    u = User(name="Alice", email="alice@example.com")
    assert u.is_valid() is True


def test_user_is_invalid():
    """User.is_valid should return False for invalid emails."""
    u = User(name="Bad", email="not-an-email")
    assert u.is_valid() is False


def test_order_creation(sample_user):
    """Order should store all fields."""
    o = Order(user=sample_user, item="Widget", quantity=3, price_cents=500)
    assert o.item == "Widget"
    assert o.quantity == 3
    assert o.price_cents == 500


def test_order_total_cents(sample_order):
    """total_cents should be quantity * price_cents."""
    assert sample_order.total_cents() == 3000
