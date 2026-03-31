import urllib.request
import urllib.error
import json


class APIClient:
    def __init__(self, base_url):
        self.base_url = base_url.rstrip('/')

    def fetch(self, path):
        url = f"{self.base_url}/{path.lstrip('/')}"
        req = urllib.request.Request(url)
        try:
            with urllib.request.urlopen(req) as resp:
                body = resp.read().decode('utf-8')
                return {
                    "status": resp.status,
                    "body": json.loads(body) if body else None,
                }
        except urllib.error.HTTPError as e:
            return {
                "status": e.code,
                "body": None,
            }
