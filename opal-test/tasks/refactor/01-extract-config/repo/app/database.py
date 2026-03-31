class Database:
    def __init__(self):
        self.url = "postgresql://localhost:5432/myapp"
        self.pool_size = 5
        self.connected = False

    def connect(self):
        self.connected = True
        return self.url

    def disconnect(self):
        self.connected = False
