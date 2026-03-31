"""Phone number validation utilities."""

import re

# Matches US phone formats: (555) 123-4567, 555-123-4567, 5551234567, etc.
PHONE_REGEX = re.compile(
    r"^\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}$"
)


def validate_phone(phone: str) -> bool:
    """Validate a US phone number.

    Accepts formats: (555) 123-4567, 555-123-4567, 555.123.4567, 5551234567

    Args:
        phone: The phone number string to validate.

    Returns:
        True if the phone number is valid, False otherwise.
    """
    if not phone or not isinstance(phone, str):
        return False
    # Strip common prefixes
    cleaned = phone.strip()
    if cleaned.startswith("+1"):
        cleaned = cleaned[2:].strip()
    if cleaned.startswith("1-"):
        cleaned = cleaned[2:].strip()
    return PHONE_REGEX.match(cleaned) is not None
