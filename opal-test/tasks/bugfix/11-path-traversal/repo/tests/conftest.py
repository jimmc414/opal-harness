"""Shared fixtures for fileserver tests."""

import os
import tempfile
import shutil

import pytest

from fileserver.app import app
from fileserver import config


@pytest.fixture
def upload_dir(tmp_path):
    """Create a temporary uploads directory with sample files."""
    uploads = tmp_path / "uploads"
    uploads.mkdir()

    # Normal files
    (uploads / "readme.txt").write_text("Hello from readme.")
    (uploads / "report.csv").write_text("id,value\n1,100\n")

    # Nested subdirectory
    sub = uploads / "subdir"
    sub.mkdir()
    (sub / "nested.txt").write_text("Nested content here.")

    # A file outside uploads (to test traversal)
    secret = tmp_path / "secret.txt"
    secret.write_text("TOP SECRET DATA")

    # Symlink inside uploads/ that points outside
    symlink = uploads / "escape.txt"
    symlink.symlink_to(secret)

    return uploads


@pytest.fixture
def client(upload_dir, monkeypatch):
    """Flask test client with UPLOAD_DIR pointed at the temporary directory."""
    monkeypatch.setattr(config, "UPLOAD_DIR", str(upload_dir))
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c
