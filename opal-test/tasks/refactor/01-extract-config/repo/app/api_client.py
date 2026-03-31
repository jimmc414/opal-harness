class APIClient:
    def __init__(self, base_url):
        self.base_url = base_url
        self.timeout = 30
        self.max_retries = 3

    def get(self, path):
        return {"url": f"{self.base_url}/{path}", "timeout": self.timeout}

    def get_config(self):
        return {"timeout": self.timeout, "max_retries": self.max_retries}
