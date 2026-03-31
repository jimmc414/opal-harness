import sqlite3


def create_v1(conn):
    conn.execute("""
        CREATE TABLE IF NOT EXISTS users (
            user_id INTEGER PRIMARY KEY,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email_addr TEXT NOT NULL UNIQUE,
            signup_date TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            user_type TEXT DEFAULT 'free'
        )
    """)

    conn.execute("""
        CREATE TABLE IF NOT EXISTS purchases (
            purchase_id INTEGER PRIMARY KEY,
            user_id INTEGER NOT NULL,
            item_name TEXT NOT NULL,
            price_cents INTEGER NOT NULL,
            purchased_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
    """)

    users = [
        (1, 'Alice', 'Smith', 'alice@example.com', '2023-01-15', 1, 'premium'),
        (2, 'Bob', 'Jones', 'bob@example.com', '2023-03-20', 1, 'free'),
        (3, 'Carol', 'White', 'carol@example.com', '2023-06-01', 0, 'premium'),
        (4, 'Dave', 'Brown', 'dave@example.com', '2024-01-10', 1, 'free'),
    ]
    conn.executemany("INSERT INTO users VALUES (?,?,?,?,?,?,?)", users)

    purchases = [
        (1, 1, 'Widget Pro', 4999, '2023-02-01T10:00:00'),
        (2, 1, 'Gadget Plus', 2499, '2023-05-15T14:30:00'),
        (3, 2, 'Widget Basic', 999, '2023-04-01T09:00:00'),
        (4, 3, 'Gadget Plus', 2499, '2023-07-20T16:45:00'),
        (5, 1, 'Support Plan', 9999, '2024-01-01T00:00:00'),
        (6, 4, 'Widget Basic', 999, '2024-02-14T11:30:00'),
    ]
    conn.executemany("INSERT INTO purchases VALUES (?,?,?,?,?)", purchases)
    conn.commit()
    return conn
