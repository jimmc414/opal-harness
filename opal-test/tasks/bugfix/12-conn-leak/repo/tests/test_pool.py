"""Unit tests for ConnectionPool."""

from database.pool import ConnectionPool
from database.connection import MockConnection


def test_acquire_and_release():
    pool = ConnectionPool(max_size=2, connection_factory=MockConnection)
    c1 = pool.acquire()
    assert pool.available == 1
    pool.release(c1)
    assert pool.available == 2


def test_pool_reuses_connections():
    pool = ConnectionPool(max_size=2, connection_factory=MockConnection)
    c1 = pool.acquire()
    pool.release(c1)
    c2 = pool.acquire()
    assert c2 is c1  # same object reused


def test_pool_exhaustion_timeout():
    pool = ConnectionPool(max_size=1, connection_factory=MockConnection)
    pool.acquire()  # take the only connection
    try:
        pool.acquire(timeout=0.1)
        assert False, "Should have raised TimeoutError"
    except TimeoutError:
        pass
