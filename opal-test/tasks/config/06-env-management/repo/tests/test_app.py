def test_list_items(client):
    resp = client.get('/api/items')
    assert resp.status_code == 200
    assert len(resp.get_json()) == 2


def test_config_endpoint(client):
    resp = client.get('/api/config')
    assert resp.status_code == 200
    data = resp.get_json()
    assert 'debug' in data
    assert 'log_level' in data
