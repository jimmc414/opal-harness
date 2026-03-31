def create_user(conn, username, email):
    cursor = conn.execute(
        "INSERT INTO users (username, email) VALUES (?, ?)",
        (username, email)
    )
    conn.commit()
    return cursor.lastrowid


def get_user(conn, user_id):
    row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if row is None:
        return None
    return dict(row)


def get_all_users(conn):
    rows = conn.execute("SELECT * FROM users").fetchall()
    return [dict(r) for r in rows]


def update_user(conn, user_id, username=None, email=None):
    user = get_user(conn, user_id)
    if user is None:
        return None
    if username is not None:
        conn.execute("UPDATE users SET username = ? WHERE id = ?", (username, user_id))
    if email is not None:
        conn.execute("UPDATE users SET email = ? WHERE id = ?", (email, user_id))
    conn.commit()
    return get_user(conn, user_id)


def delete_user(conn, user_id):
    user = get_user(conn, user_id)
    if user is None:
        return None
    conn.execute("DELETE FROM users WHERE id = ?", (user_id,))
    conn.commit()
    return user
