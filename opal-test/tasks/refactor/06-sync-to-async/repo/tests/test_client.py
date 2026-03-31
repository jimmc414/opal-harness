from unittest.mock import patch, MagicMock
import urllib.error
from httpclient.client import HttpClient


def test_get_success():
    client = HttpClient("http://api.example.com")
    mock_resp = MagicMock()
    mock_resp.status = 200
    mock_resp.read.return_value = b'{"data": "test"}'
    mock_resp.__enter__ = lambda s: s
    mock_resp.__exit__ = MagicMock(return_value=False)

    with patch('urllib.request.urlopen', return_value=mock_resp):
        result = client.get('/test')
        assert result['status'] == 200
        assert result['body'] == {"data": "test"}


def test_get_404():
    client = HttpClient("http://api.example.com")
    with patch('urllib.request.urlopen', side_effect=urllib.error.HTTPError(
        url='', code=404, msg='Not Found', hdrs=None, fp=None
    )):
        result = client.get('/missing')
        assert result['status'] == 404


def test_post_success():
    client = HttpClient("http://api.example.com")
    mock_resp = MagicMock()
    mock_resp.status = 201
    mock_resp.read.return_value = b'{"id": 1}'
    mock_resp.__enter__ = lambda s: s
    mock_resp.__exit__ = MagicMock(return_value=False)

    with patch('urllib.request.urlopen', return_value=mock_resp):
        result = client.post('/items', data={"name": "test"})
        assert result['status'] == 201
        assert result['body'] == {"id": 1}


def test_delete_success():
    client = HttpClient("http://api.example.com")
    mock_resp = MagicMock()
    mock_resp.status = 200
    mock_resp.read.return_value = b'{"deleted": true}'
    mock_resp.__enter__ = lambda s: s
    mock_resp.__exit__ = MagicMock(return_value=False)

    with patch('urllib.request.urlopen', return_value=mock_resp):
        result = client.delete('/items/1')
        assert result['status'] == 200


def test_connection_error():
    client = HttpClient("http://api.example.com")
    with patch('urllib.request.urlopen', side_effect=urllib.error.URLError("Connection refused")):
        result = client.get('/test')
        assert result['status'] == 0
        assert 'error' in result
