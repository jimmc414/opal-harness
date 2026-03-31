"""Tests for fileserver.app — including path-traversal security tests."""

import pytest


# =====================================================================
# Positive tests — serving legitimate files
# =====================================================================

def test_serve_file(client):
    """Normal file in uploads/ returns 200."""
    resp = client.get("/files/readme.txt")
    assert resp.status_code == 200
    assert b"Hello from readme" in resp.data


def test_serve_nested_file(client):
    """Nested file in uploads/subdir/ returns 200."""
    resp = client.get("/files/subdir/nested.txt")
    assert resp.status_code == 200
    assert b"Nested content" in resp.data


def test_nonexistent_file(client):
    """Request for a file that does not exist returns 404."""
    resp = client.get("/files/does_not_exist.txt")
    assert resp.status_code == 404


# =====================================================================
# Security tests — path traversal MUST be blocked
# =====================================================================

def test_path_traversal(client):
    """Path traversal with ../ must return 403 or 400, never file content."""
    resp = client.get("/files/../secret.txt")
    assert resp.status_code in (400, 403), (
        f"Expected 400 or 403 for path traversal, got {resp.status_code}. "
        f"Response body: {resp.data[:200]!r}"
    )


def test_path_traversal_encoded(client):
    """URL-encoded traversal (%2e%2e%2f) must also be blocked."""
    # Flask normalizes %2F in path segments, but let's test the app's
    # own handling of dots.
    resp = client.get("/files/..%2Fsecret.txt")
    assert resp.status_code in (400, 403, 404), (
        f"Expected 400/403/404 for encoded traversal, got {resp.status_code}"
    )


def test_path_traversal_deep(client):
    """Deep traversal must be blocked."""
    resp = client.get("/files/../../../etc/passwd")
    assert resp.status_code in (400, 403, 404), (
        f"Expected 400/403/404 for deep traversal, got {resp.status_code}"
    )


# =====================================================================
# Symlink escape — easy to overlook
# =====================================================================

def test_symlink_escape(client):
    """A symlink inside uploads/ that points outside must be rejected.

    The uploads/ directory contains ``escape.txt`` which is a symlink
    pointing to ``../secret.txt`` (outside uploads/).  The server must
    resolve the symlink and reject the request.
    """
    resp = client.get("/files/escape.txt")
    assert resp.status_code in (400, 403), (
        f"Expected 400 or 403 for symlink escape, got {resp.status_code}. "
        f"Symlinks pointing outside uploads/ must be rejected. "
        f"Response body: {resp.data[:200]!r}"
    )
