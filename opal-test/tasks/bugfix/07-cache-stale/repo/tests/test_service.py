"""Integration tests for ProductService."""

import pytest


class TestGetProduct:
    """Tests for the get_product method."""

    def test_get_product(self, service):
        """Getting a product that exists should return it."""
        product = service.get_product("p1")
        assert product is not None
        assert product["id"] == "p1"
        assert product["name"] == "Widget A"
        assert product["price"] == 19.99

    def test_get_product_not_found(self, service):
        """Getting a non-existent product should return None."""
        assert service.get_product("nonexistent") is None

    def test_cache_miss_then_hit(self, service):
        """Second get should return cached result."""
        p1 = service.get_product("p1")
        p2 = service.get_product("p1")
        assert p1 == p2


class TestUpdateThenGet:
    """Tests for cache consistency after updates."""

    def test_update_then_get(self, service):
        """After update, get_product must return the updated data.

        This is the core stale cache test. If the cache is not
        invalidated after update, the old data will be returned.
        """
        # Prime the cache
        original = service.get_product("p1")
        assert original["price"] == 19.99

        # Update the product
        service.update_product("p1", {"price": 29.99})

        # Get should reflect the update, not stale cache
        updated = service.get_product("p1")
        assert updated["price"] == 29.99, (
            f"Expected price 29.99 after update, got {updated['price']} (stale cache)"
        )

    def test_multiple_updates(self, service):
        """Multiple sequential updates should all be reflected."""
        service.get_product("p2")  # Prime cache

        service.update_product("p2", {"price": 59.99})
        p = service.get_product("p2")
        assert p["price"] == 59.99, f"First update not reflected: {p['price']}"

        service.update_product("p2", {"price": 69.99, "stock": 25})
        p = service.get_product("p2")
        assert p["price"] == 69.99, f"Second update price not reflected: {p['price']}"
        assert p["stock"] == 25, f"Second update stock not reflected: {p['stock']}"

    def test_update_without_prior_cache(self, service):
        """Updating a product that was never cached should still work."""
        # Don't prime cache — go straight to update
        service.update_product("p3", {"price": 14.99})
        product = service.get_product("p3")
        assert product["price"] == 14.99

    def test_update_preserves_other_fields(self, service):
        """Partial update should not lose unmodified fields."""
        service.get_product("p1")  # Prime cache
        service.update_product("p1", {"price": 24.99})
        product = service.get_product("p1")
        assert product["name"] == "Widget A"
        assert product["category"] == "widgets"
        assert product["price"] == 24.99


class TestListProducts:
    """Tests for the list_products method."""

    def test_list_products(self, service):
        """list_products should return all products."""
        products = service.list_products()
        assert len(products) == 3
        ids = {p["id"] for p in products}
        assert ids == {"p1", "p2", "p3"}

    def test_list_after_update(self, service):
        """list_products must reflect updates immediately.

        Even though list_products doesn't use cache, verify it
        still works correctly after cache-related changes.
        """
        service.get_product("p1")  # Prime cache
        service.update_product("p1", {"price": 99.99})
        products = service.list_products()
        p1 = next(p for p in products if p["id"] == "p1")
        assert p1["price"] == 99.99, (
            f"list_products not reflecting update: {p1['price']}"
        )
