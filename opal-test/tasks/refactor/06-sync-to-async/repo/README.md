# httpclient

A simple HTTP client library with GET, POST, and DELETE support.

## Usage

```python
from httpclient.client import HttpClient

client = HttpClient("http://api.example.com")
result = client.get("/users/1")
print(result["status"], result["body"])
```

## Testing

```bash
pytest tests/
```
