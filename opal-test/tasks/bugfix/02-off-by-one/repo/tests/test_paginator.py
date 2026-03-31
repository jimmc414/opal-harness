"""Tests for the paginator module."""

import pytest
from paginator.core import paginate, total_pages


def test_first_page(sample_items):
    """Page 1 should return items 1-10."""
    result = paginate(sample_items, page=1, per_page=10)
    assert result.items == list(range(1, 11))
    assert result.page == 1
    assert result.total_items == 25


def test_last_page(sample_items):
    """The last page should contain the remaining items."""
    result = paginate(sample_items, page=3, per_page=10)
    assert result.items == list(range(21, 26))
    assert result.page == 3


def test_page_boundary(sample_items):
    """Consecutive pages must cover all items without gaps or overlaps."""
    all_items = []
    tp = total_pages(sample_items, per_page=10)
    for p in range(1, tp + 1):
        result = paginate(sample_items, page=p, per_page=10)
        all_items.extend(result.items)
    assert all_items == sample_items


def test_single_item_pages(small_items):
    """With per_page=1, each page should have exactly one item."""
    for i, expected in enumerate(small_items, start=1):
        result = paginate(small_items, page=i, per_page=1)
        assert result.items == [expected], (
            f"Page {i} should be [{expected}], got {result.items}"
        )


def test_invalid_page_zero(sample_items):
    """page=0 should raise ValueError."""
    with pytest.raises(ValueError):
        paginate(sample_items, page=0, per_page=10)


def test_invalid_page_negative(sample_items):
    """Negative page numbers should raise ValueError."""
    with pytest.raises(ValueError):
        paginate(sample_items, page=-1, per_page=10)


def test_total_pages_calculation():
    """total_pages should correctly compute page count."""
    assert total_pages(list(range(25)), per_page=10) == 3
    assert total_pages(list(range(20)), per_page=10) == 2
    assert total_pages(list(range(1)), per_page=10) == 1
    assert total_pages([], per_page=10) == 0
