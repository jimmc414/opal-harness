"""CSV file reading utilities."""

import csv
from typing import List, Dict


def read_csv(filepath: str) -> List[Dict[str, str]]:
    """Read a CSV file and return a list of row dictionaries.

    Args:
        filepath: Path to the CSV file.

    Returns:
        List of dicts, one per row, keyed by header names.
    """
    rows = []
    with open(filepath, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(dict(row))
    return rows


def get_headers(filepath: str) -> List[str]:
    """Return the list of header names from a CSV file.

    Args:
        filepath: Path to the CSV file.

    Returns:
        List of header column names.
    """
    with open(filepath, "r") as f:
        reader = csv.DictReader(f)
        return list(reader.fieldnames or [])
