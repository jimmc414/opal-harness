"""CSV parsing module."""

import csv


def parse_csv(filepath):
    """Parse a CSV file and return a list of dictionaries.

    Each dictionary represents a row, with keys being the column headers
    and values being the corresponding cell values.

    Args:
        filepath: Path to the CSV file.

    Returns:
        List of dicts, one per row.
    """
    rows = []
    with open(filepath, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(dict(row))
    return rows
