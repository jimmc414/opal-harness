"""Email validation utilities."""

import re


EMAIL_REGEX = re.compile(
    r"^([a-zA-Z0-9_.+-]+)+@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$"
)


def validate_email(email: str) -> bool:
    """Validate an email address.

    Args:
        email: The email string to validate.

    Returns:
        True if the email is valid, False otherwise.
    """
    if not email or not isinstance(email, str):
        return False
    return EMAIL_REGEX.match(email) is not None


def extract_domain(email: str) -> str:
    """Extract the domain part from an email address.

    Args:
        email: A valid email address.

    Returns:
        The domain part (after @).

    Raises:
        ValueError: If the email doesn't contain exactly one @.
    """
    if not email or email.count("@") != 1:
        raise ValueError(f"Invalid email format: {email!r}")
    return email.split("@")[1]


def normalize_email(email: str) -> str:
    """Normalize an email address to lowercase.

    Also strips leading/trailing whitespace.

    Args:
        email: The email string to normalize.

    Returns:
        Normalized email string.
    """
    return email.strip().lower()
