def test_list_items(client):
    resp = client.get('/items')
    assert resp.status_code == 200
    assert len(resp.get_json()) == 3


def test_get_single_item(client):
    resp = client.get('/items/1')
    assert resp.status_code == 200
    assert resp.get_json()['name'] == 'Alpha'


def test_item_not_found(client):
    resp = client.get('/items/999')
    assert resp.status_code == 404
