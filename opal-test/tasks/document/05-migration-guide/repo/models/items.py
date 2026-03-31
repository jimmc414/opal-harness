_items = {}
_next_id = 1


def get_items():
    return list(_items.values())


def get_item(item_id):
    return _items.get(item_id)


def add_item(name, price=0, category='general'):
    global _next_id
    item = {"id": _next_id, "name": name, "price": price, "category": category}
    _items[_next_id] = item
    _next_id += 1
    return item


def update_item(item_id, **kwargs):
    item = _items.get(item_id)
    if not item:
        return None
    for k, v in kwargs.items():
        if k in item:
            item[k] = v
    return item


def remove_item(item_id):
    return _items.pop(item_id, None)


def reset():
    global _next_id
    _items.clear()
    _next_id = 1
