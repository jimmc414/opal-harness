import pytest


@pytest.fixture
def client():
    from client.api_client import APIClient
    return APIClient("http://api.example.com")
