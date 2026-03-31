items = {}
_next_id = 1


def create_item(name, price):
    global _next_id
    item = {"id": _next_id, "name": name, "price": price}
    items[_next_id] = item
    _next_id += 1
    return item


def get_item(item_id):
    return items.get(item_id)


def get_all_items():
    return list(items.values())


def update_item(item_id, name=None, price=None):
    item = items.get(item_id)
    if item is None:
        return None
    if name is not None:
        item["name"] = name
    if price is not None:
        item["price"] = price
    return item


def delete_item(item_id):
    return items.pop(item_id, None)


def reset():
    global _next_id
    items.clear()
    _next_id = 1
