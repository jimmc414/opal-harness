def init_db(conn):
    conn.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            processed INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()


def add_event(conn, event_type, payload):
    cursor = conn.execute(
        "INSERT INTO events (type, payload) VALUES (?, ?)",
        (event_type, payload)
    )
    conn.commit()
    return cursor.lastrowid


def get_events(conn, processed=None):
    if processed is not None:
        rows = conn.execute(
            "SELECT * FROM events WHERE processed = ?", (processed,)
        ).fetchall()
    else:
        rows = conn.execute("SELECT * FROM events").fetchall()
    return [dict(r) for r in rows]


def mark_processed(conn, event_id):
    conn.execute(
        "UPDATE events SET processed = 1 WHERE id = ?", (event_id,)
    )
    conn.commit()
