def test_create_and_list(client):
    resp = client.post('/items', json={"name": "Widget", "price": 9.99})
    assert resp.status_code == 201
    resp = client.get('/items')
    assert len(resp.get_json()) == 1


def test_get_item(client):
    client.post('/items', json={"name": "Widget", "price": 9.99})
    resp = client.get('/items/1')
    assert resp.status_code == 200


def test_update_item(client):
    client.post('/items', json={"name": "Widget", "price": 9.99})
    resp = client.put('/items/1', json={"name": "Super Widget"})
    assert resp.status_code == 200


def test_delete_item(client):
    client.post('/items', json={"name": "Widget", "price": 9.99})
    resp = client.delete('/items/1')
    assert resp.status_code == 200
