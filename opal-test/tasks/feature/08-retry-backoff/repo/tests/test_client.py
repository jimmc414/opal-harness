from unittest.mock import patch, MagicMock
import urllib.error
from client.api_client import APIClient


def test_successful_fetch():
    client = APIClient("http://api.example.com")
    mock_response = MagicMock()
    mock_response.status = 200
    mock_response.read.return_value = b'{"data": "test"}'
    mock_response.__enter__ = lambda s: s
    mock_response.__exit__ = MagicMock(return_value=False)

    with patch('urllib.request.urlopen', return_value=mock_response) as mock_urlopen:
        result = client.fetch('/test')
        assert result['status'] == 200
        assert result['body'] == {"data": "test"}
        mock_urlopen.assert_called_once()


def test_404_error():
    client = APIClient("http://api.example.com")

    with patch('urllib.request.urlopen', side_effect=urllib.error.HTTPError(
        url='http://api.example.com/test', code=404, msg='Not Found', hdrs=None, fp=None
    )) as mock_urlopen:
        result = client.fetch('/test')
        assert result['status'] == 404
        mock_urlopen.assert_called_once()
