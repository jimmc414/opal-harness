orders = {}
_next_id = 1


def create_order(customer, items):
    global _next_id
    order = {
        "id": _next_id,
        "customer": customer,
        "items": items,
        "status": "pending",
    }
    orders[_next_id] = order
    _next_id += 1
    return order


def get_order(order_id):
    return orders.get(order_id)


def update_order_status(order_id, status):
    order = orders.get(order_id)
    if order is None:
        return None
    order["status"] = status
    return order


def reset():
    global _next_id
    orders.clear()
    _next_id = 1
