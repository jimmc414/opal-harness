"""Transform utilities for CSV data."""


def filter_rows(rows, column, predicate):
    """Filter rows where predicate(row[column]) is truthy.

    Args:
        rows: List of dicts (from parse_csv).
        column: Column name to test.
        predicate: Callable that takes a cell value and returns bool.

    Returns:
        Filtered list of dicts.
    """
    return [row for row in rows if predicate(row[column])]


def sort_rows(rows, column, reverse=False):
    """Sort rows by the value of a given column.

    Args:
        rows: List of dicts (from parse_csv).
        column: Column name to sort by.
        reverse: If True, sort descending.

    Returns:
        Sorted list of dicts.
    """
    return sorted(rows, key=lambda row: row[column], reverse=reverse)
