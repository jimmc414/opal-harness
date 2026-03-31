"""Shared validation utilities."""


def is_non_empty(value: str) -> bool:
    """Check if a string is non-empty after stripping whitespace.

    Args:
        value: The string to check.

    Returns:
        True if the string is non-empty.
    """
    return bool(value and value.strip())


def max_length(value: str, limit: int) -> bool:
    """Check if a string is within a maximum length.

    Args:
        value: The string to check.
        limit: Maximum allowed length.

    Returns:
        True if len(value) <= limit.
    """
    return len(value) <= limit


def min_length(value: str, limit: int) -> bool:
    """Check if a string meets a minimum length.

    Args:
        value: The string to check.
        limit: Minimum required length.

    Returns:
        True if len(value) >= limit.
    """
    return len(value) >= limit
