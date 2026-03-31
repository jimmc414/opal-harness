"""Mock product database."""

from typing import Dict, Any, Optional, List
import copy


class ProductDB:
    """A mock database storing products in memory.

    Simulates a real database with get/update/list operations.
    """

    def __init__(self):
        self._products: Dict[str, Dict[str, Any]] = {
            "p1": {
                "id": "p1",
                "name": "Widget A",
                "price": 19.99,
                "category": "widgets",
                "stock": 100,
            },
            "p2": {
                "id": "p2",
                "name": "Gadget B",
                "price": 49.99,
                "category": "gadgets",
                "stock": 50,
            },
            "p3": {
                "id": "p3",
                "name": "Doohickey C",
                "price": 9.99,
                "category": "widgets",
                "stock": 200,
            },
        }

    def get(self, product_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve a product by ID. Returns None if not found."""
        product = self._products.get(product_id)
        if product is not None:
            return copy.deepcopy(product)
        return None

    def update(self, product_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update a product with partial data. Returns updated product or None."""
        if product_id not in self._products:
            return None
        self._products[product_id].update(data)
        return copy.deepcopy(self._products[product_id])

    def list(self) -> List[Dict[str, Any]]:
        """Return all products."""
        return [copy.deepcopy(p) for p in self._products.values()]
