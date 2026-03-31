"""Product service composing cache and database."""

from typing import Dict, Any, Optional, List
from .cache import SimpleCache
from .db import ProductDB


class ProductService:
    """Service layer for product data access with caching.

    Uses a SimpleCache for read-through caching. Database is the
    source of truth.
    """

    def __init__(self):
        self._cache = SimpleCache()
        self._db = ProductDB()

    def get_product(self, product_id: str) -> Optional[Dict[str, Any]]:
        """Get a product by ID, using cache when available.

        Checks cache first; on miss, fetches from DB and caches result.

        Args:
            product_id: The product identifier.

        Returns:
            Product dict or None if not found.
        """
        # Check cache first
        cached = self._cache.get(product_id)
        if cached is not None:
            return cached

        # Cache miss — fetch from DB
        product = self._db.get(product_id)
        if product is not None:
            self._cache.set(product_id, product)
        return product

    def update_product(
        self, product_id: str, data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """Update a product in the database.

        Args:
            product_id: The product identifier.
            data: Partial data to merge into the product.

        Returns:
            Updated product dict or None if not found.
        """
        updated = self._db.update(product_id, data)
        return updated

    def list_products(self) -> List[Dict[str, Any]]:
        """List all products from the database.

        This method does not use the cache — it always reads from
        the database directly.

        Returns:
            List of all product dicts.
        """
        return self._db.list()

    def clear_cache(self) -> None:
        """Clear the entire cache."""
        self._cache.clear()
