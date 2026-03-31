from app.database import Database
from app.api_client import APIClient


def test_database_connect():
    db = Database()
    url = db.connect()
    assert "postgresql" in url
    assert db.connected is True


def test_api_client_config():
    client = APIClient("http://api.example.com")
    config = client.get_config()
    assert config["timeout"] == 30
    assert config["max_retries"] == 3


def test_list_items(client):
    resp = client.get('/items')
    assert resp.status_code == 200
    data = resp.get_json()
    assert len(data['items']) == 20
    assert data['page_size'] == 20


def test_list_items_page2(client):
    resp = client.get('/items?page=2')
    data = resp.get_json()
    assert data['items'][0]['id'] == 21
