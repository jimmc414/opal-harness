ITEMS = [
    {"id": 1, "name": "Widget", "price": 9.99},
    {"id": 2, "name": "Gadget", "price": 24.99},
    {"id": 3, "name": "Doohickey", "price": 14.99},
]

_next_id = 4


def get_next_id():
    global _next_id
    current = _next_id
    _next_id += 1
    return current
