"""Tests for app.validators."""

from app.validators import validate_email, validate_order
from app.models import User, Order


def test_validate_email_valid():
    """Valid emails should pass validation."""
    assert validate_email("alice@example.com") is True
    assert validate_email("bob.jones@domain.org") is True


def test_validate_email_invalid():
    """Invalid emails should fail validation."""
    assert validate_email("not-an-email") is False
    assert validate_email("@example.com") is False
    assert validate_email("alice@") is False


def test_validate_email_with_whitespace():
    """Emails with surrounding whitespace should still validate."""
    assert validate_email("  alice@example.com  ") is True


def test_validate_order_valid(sample_order):
    """A valid order should pass validation."""
    assert validate_order(sample_order) is True


def test_validate_order_zero_quantity(sample_user):
    """Orders with zero quantity should fail."""
    o = Order(user=sample_user, item="Widget", quantity=0, price_cents=500)
    assert validate_order(o) is False


def test_validate_order_empty_item(sample_user):
    """Orders with empty item name should fail."""
    o = Order(user=sample_user, item="", quantity=1, price_cents=500)
    assert validate_order(o) is False
