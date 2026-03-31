import pytest
from app import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as c:
        yield c


def test_list_items(client):
    resp = client.get('/api/items')
    assert resp.status_code == 200


def test_create_item(client):
    resp = client.post('/api/items', json={"name": "Gamma"})
    assert resp.status_code == 201
