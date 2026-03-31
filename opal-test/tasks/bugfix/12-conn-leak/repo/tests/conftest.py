"""Shared fixtures for database tests."""

import pytest

from database.pool import ConnectionPool
from database.connection import MockConnection


@pytest.fixture
def pool():
    """A connection pool of size 3 with normal connections."""
    return ConnectionPool(max_size=3, connection_factory=MockConnection)


@pytest.fixture
def failing_pool():
    """A connection pool whose connections fail on SQL containing 'FAIL'."""
    def factory():
        return MockConnection(fail_patterns=[r"FAIL"])
    return ConnectionPool(max_size=3, connection_factory=factory)


@pytest.fixture
def close_failing_pool():
    """A pool whose connections raise on close() — for double-fault testing."""
    def factory():
        return MockConnection(fail_patterns=[r"FAIL"], fail_on_close=True)
    return ConnectionPool(max_size=3, connection_factory=factory)
