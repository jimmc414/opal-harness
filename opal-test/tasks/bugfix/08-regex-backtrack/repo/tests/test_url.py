"""Tests for validators.url module."""

from validators.url import validate_url


class TestValidUrls:
    """Tests for valid URLs."""

    def test_http(self):
        assert validate_url("http://example.com") is True

    def test_https(self):
        assert validate_url("https://example.com") is True

    def test_with_path(self):
        assert validate_url("https://example.com/path/to/page") is True

    def test_with_port(self):
        assert validate_url("http://localhost:8080") is True

    def test_subdomain(self):
        assert validate_url("https://sub.domain.example.com") is True


class TestInvalidUrls:
    """Tests for invalid URLs."""

    def test_no_protocol(self):
        assert validate_url("example.com") is False

    def test_ftp(self):
        assert validate_url("ftp://example.com") is False

    def test_empty(self):
        assert validate_url("") is False

    def test_none(self):
        assert validate_url(None) is False
