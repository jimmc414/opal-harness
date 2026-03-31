"""Tests for query execution — demonstrates the connection leak bug.

Tests that exercise the happy path pass.  Tests that exercise query
failures demonstrate that connections are leaked (never returned to the
pool), eventually exhausting the pool.
"""

import pytest

from database.pool import ConnectionPool
from database.connection import MockConnection, QueryError
from database.query import execute_query, execute_many


# ------------------------------------------------------------------
# Happy path — these pass even with the bug
# ------------------------------------------------------------------

def test_successful_query(pool):
    """A successful query returns results and releases its connection."""
    initial = pool.available
    results = execute_query(pool, "SELECT * FROM users")
    assert len(results) > 0
    assert pool.available == initial  # connection was returned


def test_execute_many_all_succeed(pool):
    """execute_many with no failures returns results and releases all."""
    initial = pool.available
    queries = [
        ("SELECT 1", ()),
        ("SELECT 2", ()),
        ("SELECT 3", ()),
    ]
    results = execute_many(pool, queries)
    assert len(results) == 3
    assert pool.available == initial


# ------------------------------------------------------------------
# Leak tests — these FAIL because connections are not returned on error
# ------------------------------------------------------------------

def test_failed_query_connection_leak(failing_pool):
    """After a failed query, the connection must be returned to the pool.

    With the bug: pool.available drops by 1 permanently.
    """
    initial = failing_pool.available
    with pytest.raises((QueryError, RuntimeError)):
        execute_query(failing_pool, "FAIL QUERY")
    assert failing_pool.available == initial, (
        f"Connection leaked! Pool had {initial} available before, "
        f"now has {failing_pool.available}"
    )


def test_execute_many_partial_failure(failing_pool):
    """execute_many: connections from successful queries before the failure
    must be returned, AND the connection from the failing query must also
    be returned.
    """
    initial = failing_pool.available
    queries = [
        ("SELECT 1", ()),       # succeeds
        ("SELECT 2", ()),       # succeeds
        ("FAIL QUERY", ()),      # fails
        ("SELECT 3", ()),       # never reached
    ]
    with pytest.raises((QueryError, RuntimeError)):
        execute_many(failing_pool, queries)

    assert failing_pool.available == initial, (
        f"Connection leaked on partial failure! Pool had {initial}, "
        f"now has {failing_pool.available}"
    )


def test_pool_exhaustion():
    """After many sequential failures the pool must NOT be exhausted.

    Strategy: create a pool of size 100 and run 100 failing queries.
    With the bug, pool.available drops by 1 per failure. After 100
    failures, available should still be 100 (not 0).  Because the pool
    is large enough, acquire() never blocks — the test just verifies
    that all connections were returned.
    """
    def factory():
        return MockConnection(fail_patterns=[r"FAIL"])

    pool = ConnectionPool(max_size=100, connection_factory=factory)
    initial = pool.available
    assert initial == 100

    for i in range(100):
        try:
            execute_query(pool, "FAIL QUERY")
        except (QueryError, RuntimeError):
            pass

    assert pool.available == initial, (
        f"Pool leaked connections after 100 sequential failures! "
        f"available={pool.available}, expected={initial}"
    )


# ------------------------------------------------------------------
# Double-fault: connection.close() raises during cleanup
# ------------------------------------------------------------------

def test_double_fault_close(close_failing_pool):
    """Even if the connection's close() raises, the connection must still
    be returned to the pool.

    This tests the easy-to-overlook criterion: double-fault handling.
    The close_failing_pool's connections have BOTH fail_patterns=['FAIL']
    AND fail_on_close=True.  So when a FAIL query is executed, the query
    raises QueryError, and the cleanup path also raises.
    The connection must still be returned to the pool.
    """
    initial = close_failing_pool.available

    with pytest.raises((QueryError, RuntimeError)):
        execute_query(close_failing_pool, "FAIL QUERY")

    assert close_failing_pool.available == initial, (
        f"Double-fault leak! Query raised AND close() raised, but "
        f"connection was not returned. "
        f"available={close_failing_pool.available}, expected={initial}"
    )
