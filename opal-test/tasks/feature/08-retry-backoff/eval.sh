#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task 08: Exponential Backoff Retry ==="

echo "--- Test 1: Existing tests pass ---"
python3 -m pytest tests/ -q --tb=short

echo "--- Test 2: 5xx errors trigger 3 total attempts ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch, MagicMock
import urllib.error
from client.api_client import APIClient

client = APIClient('http://api.example.com')

with patch('urllib.request.urlopen', side_effect=urllib.error.HTTPError(
    url='', code=500, msg='Internal Server Error', hdrs=None, fp=None
)) as mock:
    result = client.fetch('/test')
    assert mock.call_count == 3, f'Expected 3 attempts, got {mock.call_count}'
    assert result['status'] == 500
    print('PASS: 5xx triggers 3 total attempts')
"

echo "--- Test 3: 4xx errors are NOT retried ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch
import urllib.error
from client.api_client import APIClient

client = APIClient('http://api.example.com')

with patch('urllib.request.urlopen', side_effect=urllib.error.HTTPError(
    url='', code=404, msg='Not Found', hdrs=None, fp=None
)) as mock:
    result = client.fetch('/test')
    assert mock.call_count == 1, f'Expected 1 attempt for 4xx, got {mock.call_count}'
    assert result['status'] == 404
    print('PASS: 4xx errors are not retried (1 attempt)')
"

echo "--- Test 4: Successful retry returns success ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch, MagicMock
import urllib.error
from client.api_client import APIClient

client = APIClient('http://api.example.com')

mock_success = MagicMock()
mock_success.status = 200
mock_success.read.return_value = b'{\"data\": \"ok\"}'
mock_success.__enter__ = lambda s: s
mock_success.__exit__ = MagicMock(return_value=False)

effects = [
    urllib.error.HTTPError(url='', code=500, msg='Error', hdrs=None, fp=None),
    mock_success,
]

with patch('urllib.request.urlopen', side_effect=effects) as mock:
    result = client.fetch('/test')
    assert result['status'] == 200, f'Expected 200 on successful retry, got {result[\"status\"]}'
    assert result['body'] == {'data': 'ok'}
    print('PASS: Successful retry returns the success response')
"

echo "--- Test 5: Partial success uses exactly 2 attempts ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch, MagicMock
import urllib.error
from client.api_client import APIClient

client = APIClient('http://api.example.com')

mock_success = MagicMock()
mock_success.status = 200
mock_success.read.return_value = b'{\"data\": \"ok\"}'
mock_success.__enter__ = lambda s: s
mock_success.__exit__ = MagicMock(return_value=False)

effects = [
    urllib.error.HTTPError(url='', code=500, msg='Error', hdrs=None, fp=None),
    mock_success,
]

with patch('urllib.request.urlopen', side_effect=effects) as mock:
    result = client.fetch('/test')
    assert mock.call_count == 2, f'Expected 2 calls for 500-then-200, got {mock.call_count}'
    print('PASS: Partial success case uses exactly 2 attempts')
"

echo "--- Test 6: 503 errors also trigger retry ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch
import urllib.error
from client.api_client import APIClient

client = APIClient('http://api.example.com')

with patch('urllib.request.urlopen', side_effect=urllib.error.HTTPError(
    url='', code=503, msg='Service Unavailable', hdrs=None, fp=None
)) as mock:
    result = client.fetch('/test')
    assert mock.call_count == 3, f'Expected 3 attempts for 503, got {mock.call_count}'
    assert result['status'] == 503
    print('PASS: 503 errors trigger retry (3 attempts)')
"

echo "--- Test 7: 400 errors are NOT retried ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch
import urllib.error
from client.api_client import APIClient

client = APIClient('http://api.example.com')

with patch('urllib.request.urlopen', side_effect=urllib.error.HTTPError(
    url='', code=400, msg='Bad Request', hdrs=None, fp=None
)) as mock:
    result = client.fetch('/test')
    assert mock.call_count == 1, f'Expected 1 attempt for 400, got {mock.call_count}'
    assert result['status'] == 400
    print('PASS: 400 errors are not retried')
"

echo "--- Test 8: Backoff delays double ---"
python3 -c "
import sys
sys.path.insert(0, '.')
from unittest.mock import patch, MagicMock
import urllib.error
from client.api_client import APIClient

client = APIClient('http://api.example.com')

with patch('urllib.request.urlopen', side_effect=urllib.error.HTTPError(
    url='', code=500, msg='Internal Server Error', hdrs=None, fp=None
)):
    with patch('time.sleep') as mock_sleep:
        result = client.fetch('/test')
        assert mock_sleep.call_count >= 1, f'Expected sleep calls for backoff, got {mock_sleep.call_count}'
        delays = [call.args[0] for call in mock_sleep.call_args_list]
        for i in range(1, len(delays)):
            assert delays[i] >= delays[i-1] * 1.5, f'Delays not increasing: {delays}'
        print(f'PASS: Backoff delays are increasing: {delays}')
"

echo "=== All tests passed ==="
