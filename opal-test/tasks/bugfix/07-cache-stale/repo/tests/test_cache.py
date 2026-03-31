"""Unit tests for SimpleCache."""

import pytest


class TestSimpleCache:
    """Tests for the SimpleCache implementation."""

    def test_get_miss(self, cache):
        """Cache miss should return None."""
        assert cache.get("nonexistent") is None

    def test_set_and_get(self, cache):
        """Set a value and retrieve it."""
        cache.set("key1", {"data": "value1"})
        assert cache.get("key1") == {"data": "value1"}

    def test_overwrite(self, cache):
        """Setting the same key should overwrite."""
        cache.set("key1", "old")
        cache.set("key1", "new")
        assert cache.get("key1") == "new"

    def test_invalidate_existing(self, cache):
        """Invalidating an existing key returns True and removes it."""
        cache.set("key1", "value")
        assert cache.invalidate("key1") is True
        assert cache.get("key1") is None

    def test_invalidate_missing(self, cache):
        """Invalidating a non-existent key returns False."""
        assert cache.invalidate("missing") is False

    def test_clear(self, cache):
        """Clear removes all entries."""
        cache.set("a", 1)
        cache.set("b", 2)
        cache.clear()
        assert cache.size() == 0
        assert cache.get("a") is None

    def test_has(self, cache):
        """has() returns True for existing keys."""
        cache.set("key1", "val")
        assert cache.has("key1") is True
        assert cache.has("missing") is False

    def test_size(self, cache):
        """size() returns number of cached entries."""
        assert cache.size() == 0
        cache.set("a", 1)
        assert cache.size() == 1
        cache.set("b", 2)
        assert cache.size() == 2
        cache.invalidate("a")
        assert cache.size() == 1
