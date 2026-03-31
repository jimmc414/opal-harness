def normalize(conn):
    """
    Normalize the flat orders table into:
    - customers (id, name, email, phone)
    - products (id, name, unit_price)
    - orders (id, customer_id, product_id, quantity, order_date)

    Preserve all data.
    """
    pass
