from app.main import app


def test_index():
    with app.test_client() as c:
        resp = c.get('/')
        assert resp.status_code == 200


def test_health():
    with app.test_client() as c:
        resp = c.get('/health')
        assert resp.status_code == 200
        assert resp.get_json()['status'] == 'healthy'
