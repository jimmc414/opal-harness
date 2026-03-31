def test_create_item(client):
    resp = client.post('/api/items', json={"name": "Widget", "price": 9.99})
    assert resp.status_code == 201


def test_list_items(client):
    client.post('/api/items', json={"name": "Widget", "price": 9.99})
    resp = client.get('/api/items')
    assert resp.status_code == 200
    assert len(resp.get_json()) >= 1


def test_get_item(client):
    client.post('/api/items', json={"name": "Widget", "price": 9.99})
    resp = client.get('/api/items/1')
    assert resp.status_code == 200


def test_update_item(client):
    client.post('/api/items', json={"name": "Widget", "price": 9.99})
    resp = client.put('/api/items/1', json={"name": "Super Widget"})
    assert resp.status_code == 200


def test_delete_item(client):
    client.post('/api/items', json={"name": "Widget", "price": 9.99})
    resp = client.delete('/api/items/1')
    assert resp.status_code == 200
