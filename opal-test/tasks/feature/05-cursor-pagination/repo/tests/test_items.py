def test_default_pagination(client):
    resp = client.get('/items')
    assert resp.status_code == 200
    data = resp.get_json()
    assert len(data['items']) == 10
    assert data['total'] == 20


def test_second_page(client):
    resp = client.get('/items?page=2')
    data = resp.get_json()
    assert len(data['items']) == 10
    assert data['items'][0]['id'] == 11


def test_custom_per_page(client):
    resp = client.get('/items?per_page=5')
    data = resp.get_json()
    assert len(data['items']) == 5
