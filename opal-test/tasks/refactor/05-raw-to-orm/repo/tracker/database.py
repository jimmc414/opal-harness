import sqlite3


def get_db(path=":memory:"):
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("""
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            status TEXT DEFAULT 'todo',
            priority INTEGER DEFAULT 0
        )
    """)
    conn.commit()
    return conn


def create_task(conn, title, description="", priority=0):
    cursor = conn.execute(
        "INSERT INTO tasks (title, description, priority) VALUES (?, ?, ?)",
        (title, description, priority)
    )
    conn.commit()
    return dict(conn.execute("SELECT * FROM tasks WHERE id = ?", (cursor.lastrowid,)).fetchone())


def get_task(conn, task_id):
    row = conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()
    return dict(row) if row else None


def get_all_tasks(conn, status=None):
    if status:
        rows = conn.execute("SELECT * FROM tasks WHERE status = ?", (status,)).fetchall()
    else:
        rows = conn.execute("SELECT * FROM tasks").fetchall()
    return [dict(r) for r in rows]


def update_task(conn, task_id, **kwargs):
    task = get_task(conn, task_id)
    if task is None:
        return None
    allowed = {"title", "description", "status", "priority"}
    updates = {k: v for k, v in kwargs.items() if k in allowed}
    if not updates:
        return task
    set_clause = ", ".join(f"{k} = ?" for k in updates)
    values = list(updates.values()) + [task_id]
    conn.execute(f"UPDATE tasks SET {set_clause} WHERE id = ?", values)
    conn.commit()
    return get_task(conn, task_id)


def delete_task(conn, task_id):
    task = get_task(conn, task_id)
    if task is None:
        return None
    conn.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
    conn.commit()
    return task


def search_tasks(conn, query):
    rows = conn.execute(
        "SELECT * FROM tasks WHERE title LIKE ? OR description LIKE ?",
        (f"%{query}%", f"%{query}%")
    ).fetchall()
    return [dict(r) for r in rows]
