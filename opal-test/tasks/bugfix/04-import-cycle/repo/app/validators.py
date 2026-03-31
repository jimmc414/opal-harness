"""Validation functions for the application."""

import re
from .helpers import normalize_string


def validate_email(email):
    """Validate an email address.

    Args:
        email: Email string to validate.

    Returns:
        True if the email is valid, False otherwise.
    """
    normalized = normalize_string(email)
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, normalized))


def validate_order(order):
    """Validate an order.

    Args:
        order: An Order instance.

    Returns:
        True if the order is valid, False otherwise.
    """
    if order.quantity <= 0:
        return False
    if order.price_cents <= 0:
        return False
    if not order.item or not order.item.strip():
        return False
    return True
