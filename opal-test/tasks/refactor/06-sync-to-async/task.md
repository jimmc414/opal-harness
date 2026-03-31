# Refactor: Convert Synchronous HTTP Client to Async

## Source

Synthetic task based on a common migration pattern: converting blocking I/O code to non-blocking async/await.

## Problem

The `HttpClient` class in `httpclient/client.py` uses synchronous `urllib.request` calls. Every call to `get()`, `post()`, or `delete()` blocks the event loop, making the client unsuitable for use in async applications or concurrent request scenarios. The client needs to be converted to async so callers can `await` each method.

## Acceptance Criteria

- `HttpClient.get()`, `HttpClient.post()`, and `HttpClient.delete()` are `async` methods (coroutines)
- Methods must be callable with `await client.get('/path')`
- Return format is identical to the current implementation: `{"status": int, "body": dict|None}` on success, and `{"status": int, "body": None}` on HTTP errors
- Connection errors return `{"status": 0, "body": None, "error": "..."}` exactly as they do now
- HTTP errors (4xx/5xx) return the status code in the result dict and do not raise exceptions
- The `post` method must still set the `Content-Type: application/json` header when sending JSON data
- Tests must be updated to work with async methods (e.g., using `pytest-asyncio` or `asyncio.run`)
- All updated tests pass

## Constraints

- Do not change the constructor signature of `HttpClient`
- Do not change the return value structure of any method
- The solution must work with the Python standard library only (wrap `urllib` with `asyncio`); do not add external dependencies like `aiohttp` or `httpx`
- The class must remain importable as `from httpclient.client import HttpClient`
