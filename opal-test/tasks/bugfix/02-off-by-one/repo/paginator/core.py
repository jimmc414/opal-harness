"""Core pagination logic."""

import math
from .response import PaginatedResponse


def total_pages(items, per_page=10):
    """Calculate the total number of pages.

    Args:
        items: The full list of items.
        per_page: Number of items per page.

    Returns:
        Total page count (int).
    """
    return math.ceil(len(items) / per_page)


def paginate(items, page=1, per_page=10):
    """Return a page of items.

    Pages are 1-indexed: page=1 returns the first `per_page` items.

    Args:
        items: The full list of items.
        page: Page number (1-indexed).
        per_page: Number of items per page.

    Returns:
        PaginatedResponse with the requested page of items.
    """
    start = page * per_page
    end = (page + 1) * per_page
    tp = total_pages(items, per_page)

    return PaginatedResponse(
        items=items[start:end],
        page=page,
        per_page=per_page,
        total_pages=tp,
        total_items=len(items),
    )
