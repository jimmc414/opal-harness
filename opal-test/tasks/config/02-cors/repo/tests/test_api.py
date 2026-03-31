def test_list_items(client):
    resp = client.get('/api/items')
    assert resp.status_code == 200
    assert len(resp.get_json()) >= 2


def test_create_item(client):
    resp = client.post('/api/items', json={"name": "Doohickey", "price": 5.99})
    assert resp.status_code == 201
