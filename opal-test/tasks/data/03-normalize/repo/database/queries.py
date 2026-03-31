def get_all_orders(conn):
    rows = conn.execute("SELECT * FROM orders").fetchall()
    return [dict(r) for r in rows]


def get_orders_by_customer(conn, name):
    rows = conn.execute("SELECT * FROM orders WHERE customer_name = ?", (name,)).fetchall()
    return [dict(r) for r in rows]


def get_order_total(conn, order_id):
    row = conn.execute("SELECT quantity * unit_price as total FROM orders WHERE id = ?", (order_id,)).fetchone()
    return dict(row)['total'] if row else None
