def transform(records):
    """Transform records to target schema. All fields must match expected types."""
    transformed = []
    for record in records:
        try:
            row = {
                "id": int(record["id"]),
                "name": str(record["name"]),
                "price": float(record["price"]),
                "quantity": int(record["quantity"]),
                "active": bool(record["active"]),
            }
            transformed.append(row)
        except (TypeError, ValueError):
            pass
    return transformed
