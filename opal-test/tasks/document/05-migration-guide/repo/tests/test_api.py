def test_v1_list(client):
    resp = client.get('/api/v1/items')
    assert resp.status_code == 200
    assert 'data' in resp.get_json()


def test_v1_create(client):
    resp = client.post('/api/v1/items', json={"name": "Widget", "price": 9.99})
    assert resp.status_code == 201


def test_v2_list(client):
    resp = client.get('/api/v2/products')
    assert resp.status_code == 200
    assert 'products' in resp.get_json()


def test_v2_create(client):
    resp = client.post('/api/v2/products', json={"title": "Widget", "cost": 9.99})
    assert resp.status_code == 201
