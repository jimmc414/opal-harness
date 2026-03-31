"""Database migration runner."""

from .pool import ConnectionPool
from .query import execute_query


def run_migrations(pool: ConnectionPool, migrations: list[str]) -> list[str]:
    """Run a list of SQL migration statements.

    Returns a list of successfully applied migration SQL strings.
    Stops at the first failure and raises the exception.
    """
    applied = []
    for sql in migrations:
        execute_query(pool, sql)
        applied.append(sql)
    return applied
