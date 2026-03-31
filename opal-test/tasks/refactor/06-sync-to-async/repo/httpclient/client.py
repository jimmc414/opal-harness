import urllib.request
import urllib.error
import json


class HttpClient:
    def __init__(self, base_url):
        self.base_url = base_url.rstrip('/')

    def get(self, path):
        url = f"{self.base_url}/{path.lstrip('/')}"
        try:
            with urllib.request.urlopen(url) as resp:
                body = resp.read().decode('utf-8')
                return {"status": resp.status, "body": json.loads(body)}
        except urllib.error.HTTPError as e:
            return {"status": e.code, "body": None}
        except urllib.error.URLError as e:
            return {"status": 0, "body": None, "error": str(e.reason)}

    def post(self, path, data=None):
        url = f"{self.base_url}/{path.lstrip('/')}"
        payload = json.dumps(data).encode('utf-8') if data else None
        req = urllib.request.Request(url, data=payload, method='POST')
        req.add_header('Content-Type', 'application/json')
        try:
            with urllib.request.urlopen(req) as resp:
                body = resp.read().decode('utf-8')
                return {"status": resp.status, "body": json.loads(body)}
        except urllib.error.HTTPError as e:
            return {"status": e.code, "body": None}
        except urllib.error.URLError as e:
            return {"status": 0, "body": None, "error": str(e.reason)}

    def delete(self, path):
        url = f"{self.base_url}/{path.lstrip('/')}"
        req = urllib.request.Request(url, method='DELETE')
        try:
            with urllib.request.urlopen(req) as resp:
                body = resp.read().decode('utf-8')
                return {"status": resp.status, "body": json.loads(body) if body else None}
        except urllib.error.HTTPError as e:
            return {"status": e.code, "body": None}
        except urllib.error.URLError as e:
            return {"status": 0, "body": None, "error": str(e.reason)}
