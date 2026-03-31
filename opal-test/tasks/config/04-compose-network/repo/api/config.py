import os

DATABASE_URL = os.environ.get("DATABASE_URL", "postgres://db:5432/myapp")
API_PORT = 5000
