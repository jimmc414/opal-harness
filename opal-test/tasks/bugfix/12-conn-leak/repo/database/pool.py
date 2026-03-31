"""Thread-safe connection pool."""

import threading
from typing import Callable, Any


class ConnectionPool:
    """A fixed-size pool of reusable connections.

    Parameters
    ----------
    max_size : int
        Maximum number of connections in the pool.
    connection_factory : callable
        A zero-argument callable that creates a new connection object.
    """

    def __init__(self, max_size: int = 5, connection_factory: Callable[[], Any] = None):
        if connection_factory is None:
            raise ValueError("connection_factory is required")
        self._max_size = max_size
        self._factory = connection_factory
        self._semaphore = threading.Semaphore(max_size)
        self._lock = threading.Lock()
        self._pool: list = []
        self._created = 0

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def acquire(self, timeout: float | None = None) -> Any:
        """Acquire a connection from the pool (blocks if exhausted).

        Parameters
        ----------
        timeout : float, optional
            Seconds to wait.  ``None`` means wait forever.

        Returns
        -------
        connection
            A connection object.

        Raises
        ------
        TimeoutError
            If *timeout* expires before a connection becomes available.
        """
        acquired = self._semaphore.acquire(timeout=timeout if timeout else None)
        if not acquired:
            raise TimeoutError("Timed out waiting for a connection from the pool")

        with self._lock:
            if self._pool:
                return self._pool.pop()
            self._created += 1
            return self._factory()

    def release(self, conn: Any) -> None:
        """Return a connection to the pool."""
        with self._lock:
            self._pool.append(conn)
        self._semaphore.release()

    # ------------------------------------------------------------------
    # Diagnostics
    # ------------------------------------------------------------------

    @property
    def available(self) -> int:
        """Number of connections currently available (approximate)."""
        # Semaphore._value is CPython-specific but fine for diagnostics.
        return self._semaphore._value

    @property
    def max_size(self) -> int:
        return self._max_size

    def __repr__(self) -> str:
        return (
            f"ConnectionPool(available={self.available}, "
            f"max_size={self._max_size})"
        )
