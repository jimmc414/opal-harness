"""Tests for fileprocessor.reader module."""

import pytest
from fileprocessor.reader import read_csv, get_headers
from fileprocessor.analyzer import summarize


class TestReadRegular:
    """Tests for reading regular UTF-8 CSV files."""

    def test_read_regular(self, regular_csv):
        """Regular CSV files should be read without issues."""
        rows = read_csv(regular_csv)
        assert len(rows) == 5
        assert rows[0]["id"] == "1"
        assert rows[0]["name"] == "Alice"
        assert rows[0]["value"] == "100"

    def test_regular_headers(self, regular_csv):
        """Headers from regular CSV should be clean."""
        headers = get_headers(regular_csv)
        assert headers == ["id", "name", "value"]


class TestReadBom:
    """Tests for reading UTF-8 BOM CSV files."""

    def test_read_bom(self, bom_csv):
        """BOM CSV files should be read identically to regular files.

        The BOM character \\ufeff must not appear in any header name.
        """
        rows = read_csv(bom_csv)
        assert len(rows) == 5
        # This fails if BOM is not handled: first key becomes '\ufeffid'
        assert "id" in rows[0], (
            f"Expected 'id' in row keys, got: {list(rows[0].keys())}"
        )
        assert rows[0]["id"] == "1"
        assert rows[0]["name"] == "Alice"

    def test_header_consistency(self, regular_csv, bom_csv):
        """Headers must be identical regardless of BOM presence."""
        regular_headers = get_headers(regular_csv)
        bom_headers = get_headers(bom_csv)
        assert regular_headers == bom_headers, (
            f"Headers differ: regular={regular_headers}, bom={bom_headers}"
        )

    def test_bom_headers_no_ufeff(self, bom_csv):
        """No header should contain the BOM character."""
        headers = get_headers(bom_csv)
        for header in headers:
            assert "\ufeff" not in header, (
                f"Header '{header!r}' contains BOM character"
            )


class TestSummarizeBom:
    """Tests for analyzing BOM CSV data."""

    def test_summarize_bom(self, bom_csv):
        """summarize() should work on BOM-parsed data with correct keys."""
        rows = read_csv(bom_csv)
        stats = summarize(rows)
        # If BOM is present, the key will be '\ufeffid' instead of 'id'
        assert "id" in stats, f"Expected 'id' in stats keys, got: {list(stats.keys())}"
        assert stats["id"]["type"] == "numeric"
        assert stats["id"]["count"] == 5

    def test_summarize_values(self, bom_csv):
        """Numeric stats should be correct for BOM-parsed data."""
        rows = read_csv(bom_csv)
        stats = summarize(rows)
        assert stats["value"]["min"] == 100.0
        assert stats["value"]["max"] == 300.0
        assert stats["value"]["mean"] == 200.0


class TestNonBomFilesUnaffected:
    """Ensure the fix does not corrupt non-BOM files."""

    def test_regular_still_works(self, regular_csv):
        """Regular files must produce identical results after any fix."""
        rows = read_csv(regular_csv)
        assert len(rows) == 5
        headers = get_headers(regular_csv)
        assert headers == ["id", "name", "value"]
        assert rows[2]["name"] == "Charlie"
        assert rows[4]["value"] == "250"
