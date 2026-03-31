"""Utility helper functions."""

from .models import User


def normalize_string(value):
    """Normalize a string by stripping whitespace and lowercasing.

    Args:
        value: String to normalize.

    Returns:
        Normalized string.
    """
    return value.strip().lower()


def format_currency(cents):
    """Format a cent amount as a dollar string.

    Args:
        cents: Integer amount in cents.

    Returns:
        Formatted string like "$19.99".
    """
    dollars = cents / 100
    return f"${dollars:.2f}"


def user_display(user: User) -> str:
    """Format a User for display.

    Args:
        user: A User instance.

    Returns:
        Display string like "Alice <alice@example.com>".
    """
    return f"{user.name} <{user.email}>"
