import sqlite3


def create_db(path=":memory:"):
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("""
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY,
            customer_name TEXT NOT NULL,
            customer_email TEXT NOT NULL,
            customer_phone TEXT,
            product TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL,
            order_date TEXT NOT NULL
        )
    """)

    orders = [
        (1, 'Alice Smith', 'alice@example.com', '555-0101', 'Widget', 3, 9.99, '2024-01-15'),
        (2, 'Alice Smith', 'alice@example.com', '555-0101', 'Gadget', 1, 24.99, '2024-01-20'),
        (3, 'Bob Jones', 'bob@example.com', None, 'Widget', 5, 9.99, '2024-02-01'),
        (4, 'Carol White', 'carol@example.com', '555-0303', 'Doohickey', 2, 14.99, '2024-02-15'),
        (5, 'Alice Smith', 'alice@example.com', '555-0101', 'Doohickey', 1, 14.99, '2024-03-01'),
        (6, 'Bob Jones', 'bob@example.com', '555-0202', 'Gadget', 2, 24.99, '2024-03-10'),
        (7, 'Dave Brown', 'dave@example.com', None, 'Widget', 10, 9.99, '2024-03-15'),
    ]
    conn.executemany("INSERT INTO orders VALUES (?,?,?,?,?,?,?,?)", orders)
    conn.commit()
    return conn
