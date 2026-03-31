items = {}
_next_id = 1


def create_item(name, price, category="general"):
    global _next_id
    item = {"id": _next_id, "name": name, "price": price, "category": category}
    items[_next_id] = item
    _next_id += 1
    return item


def get_item(item_id):
    return items.get(item_id)


def get_all_items():
    return list(items.values())


def update_item(item_id, **kwargs):
    item = items.get(item_id)
    if not item:
        return None
    for k, v in kwargs.items():
        if k in item and v is not None:
            item[k] = v
    return item


def delete_item(item_id):
    return items.pop(item_id, None)


def reset():
    global _next_id
    items.clear()
    _next_id = 1
