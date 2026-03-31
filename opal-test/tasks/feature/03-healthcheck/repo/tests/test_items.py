def test_list_items(client):
    resp = client.get('/items')
    assert resp.status_code == 200
    assert len(resp.get_json()) == 3


def test_get_item(client):
    resp = client.get('/items/1')
    assert resp.status_code == 200
    assert resp.get_json()['name'] == 'Widget'


def test_get_missing_item(client):
    resp = client.get('/items/999')
    assert resp.status_code == 404


def test_create_item(client):
    resp = client.post('/items', json={"name": "Thingamajig", "price": 5.99})
    assert resp.status_code == 201
    assert resp.get_json()['name'] == 'Thingamajig'
