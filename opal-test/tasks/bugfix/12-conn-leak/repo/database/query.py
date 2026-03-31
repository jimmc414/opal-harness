"""Query execution helpers."""

from __future__ import annotations

from typing import Any, Sequence


def execute_query(
    pool,
    sql: str,
    params: Sequence[Any] = (),
) -> list[tuple]:
    """Execute a single query and return the results.

    Acquires a connection from *pool*, runs the query, and returns it.
    """
    conn = pool.acquire()
    conn.execute(sql, params)
    results = conn.fetchall()
    pool.release(conn)
    return results


def execute_many(
    pool,
    queries: Sequence[tuple[str, Sequence[Any]]],
) -> list[list[tuple]]:
    """Execute multiple queries sequentially, each on its own connection.

    Returns a list of result sets (one per query).
    """
    all_results: list[list[tuple]] = []

    for sql, params in queries:
        conn = pool.acquire()
        conn.execute(sql, params)
        all_results.append(conn.fetchall())
        pool.release(conn)

    return all_results
