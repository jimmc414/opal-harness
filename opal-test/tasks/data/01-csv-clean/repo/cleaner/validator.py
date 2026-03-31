def validate_row(row):
    """Return a cleaned row dict, or None if the row should be skipped."""
    return row


def clean_dataset(rows):
    """Clean and validate all rows. Return list of valid, cleaned rows."""
    return [r for r in (validate_row(row) for row in rows) if r is not None]
