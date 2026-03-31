"""URL validation utilities."""

import re

URL_REGEX = re.compile(
    r"^https?://"
    r"[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?"
    r"(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*"
    r"(:\d{1,5})?"
    r"(/[^\s]*)?$"
)


def validate_url(url: str) -> bool:
    """Validate a URL (http or https).

    Args:
        url: The URL string to validate.

    Returns:
        True if the URL is valid, False otherwise.
    """
    if not url or not isinstance(url, str):
        return False
    return URL_REGEX.match(url) is not None
