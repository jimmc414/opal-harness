"""Tests for the user profile API routes."""

import json


def test_get_user_with_email(client):
    """GET /users/1 should return Alice with a lowercase email."""
    resp = client.get("/users/1")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["display_name"] == "Alice Smith"
    assert data["email"] == "alice.smith@example.com"
    assert data["age"] == 30


def test_get_user_without_email(client):
    """GET /users/3 should return Charlie with null email, not crash."""
    resp = client.get("/users/3")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["display_name"] == "Charlie Brown"
    assert data["email"] is None  # Must be null, not empty string
    assert data["age"] == 35


def test_get_user_not_found(client):
    """GET /users/999 should return 404."""
    resp = client.get("/users/999")
    assert resp.status_code == 404


def test_list_users(client):
    """GET /users/ should return all users without error."""
    resp = client.get("/users/")
    assert resp.status_code == 200
    data = resp.get_json()
    assert isinstance(data, list)
    assert len(data) == 5
    # Verify the null-email users are present and correct
    charlie = next(u for u in data if u["display_name"] == "Charlie Brown")
    assert charlie["email"] is None


def test_null_email_is_not_empty_string(client):
    """The email field for null-email users must be JSON null, not ''."""
    resp = client.get("/users/3")
    raw = resp.get_data(as_text=True)
    parsed = json.loads(raw)
    # Explicitly check it's None/null, not empty string
    assert parsed["email"] is None, (
        f"Expected null, got {repr(parsed['email'])}"
    )
    assert parsed["email"] != ""


def test_second_null_email_user(client):
    """GET /users/5 should also handle null email."""
    resp = client.get("/users/5")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["display_name"] == "Eve Taylor"
    assert data["email"] is None
