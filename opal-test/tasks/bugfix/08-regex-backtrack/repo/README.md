# validators

A Python input validation library providing email, URL, and phone number validation.

## Features

- Email validation with domain extraction and normalization
- URL validation (http/https)
- Phone number validation (US format)
- Common shared utilities (non-empty check, max length)

## Usage

```python
from validators.email import validate_email, extract_domain, normalize_email
from validators.url import validate_url
from validators.phone import validate_phone

assert validate_email("user@example.com") is True
assert extract_domain("user@example.com") == "example.com"
assert validate_url("https://example.com") is True
assert validate_phone("(555) 123-4567") is True
```

## Project Structure

```
validators/
    __init__.py
    email.py        # Email validation, domain extraction, normalization
    url.py          # URL validation
    phone.py        # Phone number validation
    common.py       # Shared utilities
tests/
    conftest.py
    test_email.py   # Email validator tests
    test_url.py     # URL validator tests
```

## Running Tests

```bash
pytest tests/ -v
```
