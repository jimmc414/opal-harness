"""Paginated response container."""

from dataclasses import dataclass
from typing import Any, List


@dataclass
class PaginatedResponse:
    """Container for a page of results.

    Attributes:
        items: The items on this page.
        page: The current page number (1-indexed).
        per_page: Number of items per page.
        total_pages: Total number of pages.
        total_items: Total number of items across all pages.
    """
    items: List[Any]
    page: int
    per_page: int
    total_pages: int
    total_items: int
