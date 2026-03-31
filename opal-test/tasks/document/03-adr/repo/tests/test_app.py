def test_create_event(client):
    resp = client.post(
        '/api/events',
        json={"type": "user.signup", "payload": {"user": "alice"}}
    )
    assert resp.status_code == 201
    assert 'id' in resp.get_json()


def test_list_events(client):
    client.post(
        '/api/events',
        json={"type": "user.signup", "payload": {"user": "alice"}}
    )
    resp = client.get('/api/events')
    assert resp.status_code == 200
    assert len(resp.get_json()) >= 1


def test_process_events(client):
    client.post(
        '/api/events',
        json={"type": "order.placed", "payload": {"item": "widget"}}
    )
    resp = client.post('/api/process')
    assert resp.status_code == 200
    data = resp.get_json()
    assert data['processed'] >= 1
