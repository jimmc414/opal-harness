import pytest
from app import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as c:
        yield c


def test_index(client):
    resp = client.get('/')
    assert resp.status_code == 200
    assert resp.get_json()['message'] == 'Hello, World!'


def test_health(client):
    resp = client.get('/health')
    assert resp.status_code == 200
    assert resp.get_json()['status'] == 'healthy'
