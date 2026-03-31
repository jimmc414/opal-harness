from api.config import DATABASE_URL, API_PORT


def get_db_host():
    parts = DATABASE_URL.split("://")[1] if "://" in DATABASE_URL else DATABASE_URL
    host = parts.split(":")[0].split("@")[-1]
    return host


def get_config():
    return {"db_host": get_db_host(), "port": API_PORT}
