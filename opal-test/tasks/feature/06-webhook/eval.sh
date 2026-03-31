#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task 06: Webhook Support ==="

echo "--- Test 1: Existing tests pass ---"
python3 -m pytest tests/ -q --tb=short

echo "--- Test 2: POST /webhooks registers a webhook ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

resp = client.post('/webhooks', json={'url': 'http://example.com/hook'})
assert resp.status_code == 201, f'Expected 201, got {resp.status_code}'
data = resp.get_json()
assert 'id' in data, 'Webhook response missing id'
assert data['url'] == 'http://example.com/hook', 'URL mismatch'
print('PASS: POST /webhooks returns 201 with webhook data')
"

echo "--- Test 3: GET /webhooks lists registered webhooks ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/webhooks', json={'url': 'http://example.com/hook1'})
client.post('/webhooks', json={'url': 'http://example.com/hook2'})

resp = client.get('/webhooks')
assert resp.status_code == 200, f'Expected 200, got {resp.status_code}'
data = resp.get_json()
assert isinstance(data, list), 'Expected a list'
assert len(data) == 2, f'Expected 2 webhooks, got {len(data)}'
urls = [w['url'] for w in data]
assert 'http://example.com/hook1' in urls
assert 'http://example.com/hook2' in urls
print('PASS: GET /webhooks returns list of registered webhooks')
"

echo "--- Test 4: Status change triggers webhook notification ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch, MagicMock
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

client.post('/webhooks', json={'url': 'http://example.com/hook'})
client.post('/orders', json={'customer': 'Alice', 'items': ['widget']})

with patch('urllib.request.urlopen') as mock_urlopen:
    mock_urlopen.return_value = MagicMock()
    mock_urlopen.return_value.__enter__ = lambda s: s
    mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)
    mock_urlopen.return_value.read.return_value = b''

    resp = client.put('/orders/1/status', json={'status': 'shipped'})
    assert resp.status_code == 200, f'Expected 200, got {resp.status_code}'

    if mock_urlopen.called:
        print('PASS: Webhook notification triggered via urllib')
    else:
        try:
            with patch('requests.post') as mock_requests:
                mock_requests.return_value = MagicMock(status_code=200)
                models.reset()

                client2 = app.test_client()
                client2.post('/webhooks', json={'url': 'http://example.com/hook'})
                client2.post('/orders', json={'customer': 'Alice', 'items': ['widget']})
                client2.put('/orders/1/status', json={'status': 'shipped'})

                assert mock_requests.called, 'Neither urllib.request.urlopen nor requests.post was called'
                print('PASS: Webhook notification triggered via requests')
        except ImportError:
            assert False, 'Webhook notification was not triggered'
"

echo "--- Test 5: DELETE /webhooks/<id> removes webhook ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

resp = client.post('/webhooks', json={'url': 'http://example.com/hook'})
wh_id = resp.get_json()['id']

resp = client.delete(f'/webhooks/{wh_id}')
assert resp.status_code in (200, 204), f'Expected 200/204, got {resp.status_code}'

resp = client.get('/webhooks')
data = resp.get_json()
assert len(data) == 0, f'Expected 0 webhooks after delete, got {len(data)}'
print('PASS: DELETE /webhooks/<id> removes the webhook')
"

echo "--- Test 6: Deleted webhook not triggered ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch, MagicMock
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

resp = client.post('/webhooks', json={'url': 'http://example.com/hook'})
wh_id = resp.get_json()['id']
client.delete(f'/webhooks/{wh_id}')

client.post('/orders', json={'customer': 'Alice', 'items': ['widget']})

with patch('urllib.request.urlopen') as mock_urlopen:
    mock_urlopen.return_value = MagicMock()
    mock_urlopen.return_value.__enter__ = lambda s: s
    mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

    try:
        import requests as _req_mod
        with patch('requests.post') as mock_requests:
            client.put('/orders/1/status', json={'status': 'shipped'})
            assert not mock_urlopen.called, 'Deleted webhook triggered via urllib'
            assert not mock_requests.called, 'Deleted webhook triggered via requests'
    except ImportError:
        client.put('/orders/1/status', json={'status': 'shipped'})
        assert not mock_urlopen.called, 'Deleted webhook should not be triggered'

    print('PASS: Deleted webhook is not triggered')
"

echo "--- Test 7: POST /webhooks with no URL returns 400 ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import create_app
from app import models

app = create_app()
app.config['TESTING'] = True
models.reset()
client = app.test_client()

resp = client.post('/webhooks', json={})
assert resp.status_code == 400, f'Expected 400, got {resp.status_code}'
print('PASS: POST /webhooks with no URL returns 400')
"

echo "=== All tests passed ==="
