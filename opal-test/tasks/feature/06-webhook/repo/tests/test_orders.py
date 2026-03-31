def test_create_order(client):
    resp = client.post('/orders', json={"customer": "Alice", "items": ["widget"]})
    assert resp.status_code == 201
    data = resp.get_json()
    assert data['customer'] == 'Alice'
    assert data['status'] == 'pending'


def test_get_order(client):
    client.post('/orders', json={"customer": "Bob", "items": ["gadget"]})
    resp = client.get('/orders/1')
    assert resp.status_code == 200
    assert resp.get_json()['customer'] == 'Bob'


def test_get_missing_order(client):
    resp = client.get('/orders/999')
    assert resp.status_code == 404


def test_update_status(client):
    client.post('/orders', json={"customer": "Carol", "items": ["thing"]})
    resp = client.put('/orders/1/status', json={"status": "shipped"})
    assert resp.status_code == 200
    assert resp.get_json()['status'] == 'shipped'


def test_update_missing_order_status(client):
    resp = client.put('/orders/999/status', json={"status": "shipped"})
    assert resp.status_code == 404
