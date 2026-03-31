from web.config import API_HOST, TIMEOUT


def get_api_url(path):
    return f"{API_HOST}/{path.lstrip('/')}"


def fetch_items():
    url = get_api_url("/items")
    return {"url": url, "timeout": TIMEOUT}
