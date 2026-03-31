def create_v2_tables(conn):
    """Create v2 schema tables (empty). Data must be migrated from v1."""
    conn.execute("""
        CREATE TABLE IF NOT EXISTS accounts (
            id INTEGER PRIMARY KEY,
            full_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            created_at TEXT NOT NULL,
            active INTEGER DEFAULT 1,
            tier TEXT DEFAULT 'basic'
        )
    """)

    conn.execute("""
        CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY,
            account_id INTEGER NOT NULL,
            description TEXT NOT NULL,
            amount_dollars REAL NOT NULL,
            transaction_date TEXT NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id)
        )
    """)
    conn.commit()
