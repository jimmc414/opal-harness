"""Mock database connection for testing.

``MockConnection`` simulates a database connection.  It can be configured to
raise exceptions on specific SQL patterns for testing error handling paths.
"""

from __future__ import annotations

import re
from typing import Any, Sequence


class MockConnection:
    """Simulated database connection.

    Parameters
    ----------
    fail_patterns : list[str]
        Regex patterns.  If ``execute`` receives SQL matching any of these
        patterns, it raises ``QueryError``.
    fail_on_close : bool
        If ``True``, calling ``close()`` will raise ``ConnectionError``.
    """

    def __init__(
        self,
        fail_patterns: list[str] | None = None,
        fail_on_close: bool = False,
    ):
        self._fail_patterns = [re.compile(p) for p in (fail_patterns or [])]
        self._fail_on_close = fail_on_close
        self._results: list[tuple] = []
        self._closed = False

    # ------------------------------------------------------------------
    # Query interface
    # ------------------------------------------------------------------

    def execute(self, sql: str, params: Sequence[Any] = ()) -> None:
        """Execute a SQL statement.  May raise ``QueryError``."""
        if self._closed:
            raise ConnectionError("Connection is closed")

        for pat in self._fail_patterns:
            if pat.search(sql):
                raise QueryError(f"Simulated failure on: {sql}")

        # Simulate a result set
        self._results = [("row1_col1", "row1_col2"), ("row2_col1", "row2_col2")]

    def fetchall(self) -> list[tuple]:
        """Return the results of the last ``execute``."""
        return list(self._results)

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def close(self) -> None:
        """Close the connection.  May raise if ``fail_on_close`` is set."""
        if self._fail_on_close:
            raise ConnectionError("Simulated close failure")
        self._closed = True

    @property
    def closed(self) -> bool:
        return self._closed

    def __repr__(self) -> str:
        state = "closed" if self._closed else "open"
        return f"MockConnection({state})"


class QueryError(Exception):
    """Raised when a query fails."""
