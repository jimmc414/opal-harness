def test_list_all_items(client):
    resp = client.get('/items')
    assert resp.status_code == 200
    data = resp.get_json()
    assert len(data) == 5


def test_items_have_required_fields(client):
    resp = client.get('/items')
    data = resp.get_json()
    for item in data:
        assert 'id' in item
        assert 'name' in item
        assert 'description' in item
