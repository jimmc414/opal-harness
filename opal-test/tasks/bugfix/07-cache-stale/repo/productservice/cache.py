"""Simple in-memory cache implementation."""

from typing import Any, Optional, Dict


class SimpleCache:
    """A simple key-value in-memory cache."""

    def __init__(self):
        self._store: Dict[str, Any] = {}

    def get(self, key: str) -> Optional[Any]:
        """Retrieve a value from cache. Returns None on miss."""
        return self._store.get(key)

    def set(self, key: str, value: Any) -> None:
        """Store a value in cache."""
        self._store[key] = value

    def invalidate(self, key: str) -> bool:
        """Remove a key from cache. Returns True if key existed."""
        if key in self._store:
            del self._store[key]
            return True
        return False

    def clear(self) -> None:
        """Remove all entries from cache."""
        self._store.clear()

    def has(self, key: str) -> bool:
        """Check if a key exists in cache."""
        return key in self._store

    def size(self) -> int:
        """Return the number of cached entries."""
        return len(self._store)
