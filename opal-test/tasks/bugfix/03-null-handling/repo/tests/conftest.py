"""Shared fixtures for user API tests."""

import pytest
from app.routes import create_app


@pytest.fixture
def app():
    """Create a Flask test application."""
    app = create_app()
    app.config["TESTING"] = True
    return app


@pytest.fixture
def client(app):
    """Create a Flask test client."""
    return app.test_client()
