import pytest
from app.main import app


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_index(client):
    resp = client.get('/')
    assert resp.status_code == 200
    assert resp.get_json()['message'] == 'Welcome'


def test_status(client):
    resp = client.get('/api/status')
    assert resp.status_code == 200
    assert resp.get_json()['status'] == 'ok'
