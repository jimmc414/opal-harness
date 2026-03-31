"""Tests for validators.email module."""

import signal
import pytest
from validators.email import validate_email, extract_domain, normalize_email


class TimeoutError(Exception):
    pass


def _timeout_handler(signum, frame):
    raise TimeoutError("Function call timed out")


class TestValidEmails:
    """Tests for valid email addresses."""

    def test_simple_email(self):
        assert validate_email("user@example.com") is True

    def test_email_with_dots(self):
        assert validate_email("first.last@example.com") is True

    def test_email_with_plus(self):
        assert validate_email("user+tag@example.com") is True

    def test_email_with_hyphen_domain(self):
        assert validate_email("user@my-domain.com") is True

    def test_email_with_subdomain(self):
        assert validate_email("user@mail.example.co.uk") is True

    def test_long_valid_email(self):
        """A long but valid email should pass."""
        local = "a" * 50
        assert validate_email(f"{local}@example.com") is True


class TestInvalidEmails:
    """Tests for invalid email addresses."""

    def test_no_at_sign(self):
        assert validate_email("userexample.com") is False

    def test_no_domain(self):
        assert validate_email("user@") is False

    def test_no_local_part(self):
        assert validate_email("@example.com") is False

    def test_empty_string(self):
        assert validate_email("") is False

    def test_none(self):
        assert validate_email(None) is False

    def test_double_at(self):
        assert validate_email("user@@example.com") is False

    def test_consecutive_dots_in_domain(self):
        """Emails with consecutive dots in the domain must be rejected."""
        assert validate_email("user@foo..bar.com") is False

    def test_trailing_dot_in_domain(self):
        """Emails with a trailing dot in the domain should be rejected."""
        assert validate_email("user@example.com.") is False

    def test_domain_only_dot(self):
        assert validate_email("user@.com") is False


class TestAdversarialInput:
    """Tests for catastrophic backtracking resistance."""

    def test_adversarial_input(self):
        """Adversarial input must not cause catastrophic backtracking.

        The input 'aaa...@' (valid local part, no valid domain) must
        be rejected in under 2 seconds. A vulnerable regex will take
        exponential time on this input.
        """
        adversarial = "a" * 30 + "@"

        # Set a 2-second timeout
        old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
        signal.alarm(2)
        try:
            result = validate_email(adversarial)
            assert result is False, "Adversarial input should be rejected"
        except TimeoutError:
            pytest.fail(
                "validate_email took >2 seconds on adversarial input — "
                "catastrophic backtracking detected"
            )
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)

    def test_adversarial_with_partial_domain(self):
        """Adversarial input with a partial domain must not backtrack."""
        adversarial = "a" * 30 + "@b"

        old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
        signal.alarm(2)
        try:
            result = validate_email(adversarial)
            assert result is False
        except TimeoutError:
            pytest.fail(
                "validate_email took >2 seconds on partial domain input"
            )
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)

    def test_adversarial_dots_in_local(self):
        """Many dots in local part must not cause backtracking."""
        adversarial = "a.b." * 15 + "@"

        old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
        signal.alarm(2)
        try:
            result = validate_email(adversarial)
            assert result is False
        except TimeoutError:
            pytest.fail(
                "validate_email took >2 seconds on dotted local part"
            )
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)


class TestExtractDomain:
    """Tests for extract_domain function."""

    def test_extract_simple(self):
        assert extract_domain("user@example.com") == "example.com"

    def test_extract_subdomain(self):
        assert extract_domain("a@b.c.d.com") == "b.c.d.com"

    def test_extract_no_at(self):
        with pytest.raises(ValueError):
            extract_domain("nope")


class TestNormalizeEmail:
    """Tests for normalize_email function."""

    def test_lowercase(self):
        assert normalize_email("User@Example.COM") == "user@example.com"

    def test_strip_whitespace(self):
        assert normalize_email("  user@example.com  ") == "user@example.com"
