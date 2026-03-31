import sqlite3

_db_path = ":memory:"


def get_connection(db_path=None):
    conn = sqlite3.connect(db_path or _db_path)
    conn.row_factory = sqlite3.Row
    return conn
