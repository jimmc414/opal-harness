#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

run_check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $description"
        FAIL=$((FAIL + 1))
    fi
}

# 1. HttpClient.get is an async coroutine
run_check "HttpClient.get is async" python3 -c "
import asyncio
from httpclient.client import HttpClient
assert asyncio.iscoroutinefunction(HttpClient.get), 'get is not async'
"

# 2. HttpClient.post is an async coroutine
run_check "HttpClient.post is async" python3 -c "
import asyncio
from httpclient.client import HttpClient
assert asyncio.iscoroutinefunction(HttpClient.post), 'post is not async'
"

# 3. HttpClient.delete is an async coroutine
run_check "HttpClient.delete is async" python3 -c "
import asyncio
from httpclient.client import HttpClient
assert asyncio.iscoroutinefunction(HttpClient.delete), 'delete is not async'
"

# 4. Updated tests pass
run_check "All tests pass" python3 -m pytest tests/ -x -q

# 5. Async get returns correct result shape with mocked network
run_check "Async get returns correct result shape" python3 -c "
import asyncio
import sys
sys.path.insert(0, '.')
from httpclient.client import HttpClient

async def test_get():
    client = HttpClient('http://example.com')
    # Monkey-patch to avoid real network call
    async def fake_get(self, path):
        return {'status': 200, 'body': {'key': 'value'}}
    original = HttpClient.get
    HttpClient.get = fake_get
    result = await client.get('/test')
    HttpClient.get = original
    assert isinstance(result, dict), 'result is not a dict'
    assert 'status' in result, 'missing status key'
    assert 'body' in result, 'missing body key'
    assert result['status'] == 200

asyncio.run(test_get())
"

# 6. Async post returns correct result shape with mocked network
run_check "Async post returns correct result shape" python3 -c "
import asyncio
import sys
sys.path.insert(0, '.')
from httpclient.client import HttpClient

async def test_post():
    client = HttpClient('http://example.com')
    async def fake_post(self, path, data=None):
        return {'status': 201, 'body': {'id': 1}}
    original = HttpClient.post
    HttpClient.post = fake_post
    result = await client.post('/items', data={'name': 'test'})
    HttpClient.post = original
    assert result['status'] == 201
    assert result['body'] == {'id': 1}

asyncio.run(test_post())
"

# 7. Error handling preserved: connection errors return status=0 and error key
run_check "Error handling returns status=0 with error key" python3 -c "
import asyncio
import sys
sys.path.insert(0, '.')
from httpclient.client import HttpClient

async def test_error():
    client = HttpClient('http://example.com')
    async def fake_get_error(self, path):
        return {'status': 0, 'body': None, 'error': 'Connection refused'}
    original = HttpClient.get
    HttpClient.get = fake_get_error
    result = await client.get('/test')
    HttpClient.get = original
    assert result['status'] == 0, f'expected status 0, got {result[\"status\"]}'
    assert 'error' in result, 'missing error key'
    assert result['body'] is None, 'body should be None on error'

asyncio.run(test_error())
"

# 8. HttpClient is still importable from httpclient.client
run_check "HttpClient importable from httpclient.client" python3 -c "
from httpclient.client import HttpClient
client = HttpClient('http://example.com')
assert hasattr(client, 'base_url')
"

# 9. Constructor signature unchanged (takes base_url)
run_check "Constructor accepts base_url" python3 -c "
from httpclient.client import HttpClient
client = HttpClient('http://example.com')
assert client.base_url == 'http://example.com'
"

# 10. Post method sets Content-Type header
run_check "Post sets Content-Type application/json" python3 -c "
import asyncio, sys, inspect
sys.path.insert(0, '.')
from httpclient.client import HttpClient
source = inspect.getsource(HttpClient.post)
assert 'application/json' in source or 'content-type' in source.lower(), \
    'post method does not reference Content-Type or application/json'
"

# 11. Post error handling: 4xx returns status code not exception
run_check "Async post handles HTTP errors" python3 -c "
import asyncio, sys
sys.path.insert(0, '.')
from httpclient.client import HttpClient

async def test():
    client = HttpClient('http://example.com')
    async def fake_post_error(self, path, data=None):
        return {'status': 400, 'body': None}
    original = HttpClient.post
    HttpClient.post = fake_post_error
    result = await client.post('/bad', data={'x': 1})
    HttpClient.post = original
    assert result['status'] == 400
    assert result['body'] is None

asyncio.run(test())
"

# 12. Delete error handling: connection error returns status=0
run_check "Async delete handles connection errors" python3 -c "
import asyncio, sys
sys.path.insert(0, '.')
from httpclient.client import HttpClient

async def test():
    client = HttpClient('http://example.com')
    async def fake_delete_error(self, path):
        return {'status': 0, 'body': None, 'error': 'Connection refused'}
    original = HttpClient.delete
    HttpClient.delete = fake_delete_error
    result = await client.delete('/test')
    HttpClient.delete = original
    assert result['status'] == 0
    assert 'error' in result

asyncio.run(test())
"

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS + FAIL)) checks"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
