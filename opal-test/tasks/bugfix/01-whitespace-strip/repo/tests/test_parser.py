"""Tests for csvlib.parser and csvlib.transforms."""

from csvlib.parser import parse_csv
from csvlib.transforms import filter_rows, sort_rows


def test_parse_headers(sample_csv_path):
    """Headers should be clean strings without surrounding whitespace."""
    rows = parse_csv(sample_csv_path)
    expected_keys = {"id", "name", "email", "age"}
    actual_keys = set(rows[0].keys())
    assert actual_keys == expected_keys, (
        f"Expected keys {expected_keys}, got {actual_keys}"
    )


def test_parse_values(sample_csv_path):
    """Values for the first row should be accessible by clean key names."""
    rows = parse_csv(sample_csv_path)
    assert rows[0]["name"] == "Alice"
    assert rows[0]["age"] == "30"
    assert rows[0]["email"] == "alice@example.com"


def test_filter_rows(sample_csv_path):
    """filter_rows should work with clean column names on sample.csv."""
    rows = parse_csv(sample_csv_path)
    adults = filter_rows(rows, "age", lambda x: int(x) >= 30)
    assert len(adults) == 2  # Alice (30) and Charlie (35)
    names = {r["name"] for r in adults}
    assert names == {"Alice", "Charlie"}


def test_sort_rows(sample_csv_path):
    """sort_rows should sort by a clean column name."""
    rows = parse_csv(sample_csv_path)
    sorted_by_name = sort_rows(rows, "name")
    names = [r["name"] for r in sorted_by_name]
    assert names == ["Alice", "Bob", "Charlie", "Diana"]


def test_clean_csv_still_works(clean_csv_path):
    """Parsing a CSV without whitespace issues should still work."""
    rows = parse_csv(clean_csv_path)
    assert len(rows) == 4
    assert rows[0]["name"] == "Alice"
    assert set(rows[0].keys()) == {"id", "name", "email", "age"}
