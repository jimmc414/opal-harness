"""Data analysis and summarization utilities."""

from typing import List, Dict, Any


def summarize(rows: List[Dict[str, str]]) -> Dict[str, Dict[str, Any]]:
    """Compute summary statistics for each column.

    For numeric columns: returns min, max, mean, count.
    For non-numeric columns: returns count and unique count.

    Args:
        rows: List of row dictionaries (as returned by read_csv).

    Returns:
        Dict mapping column name to a stats dictionary.
    """
    if not rows:
        return {}

    headers = list(rows[0].keys())
    stats: Dict[str, Dict[str, Any]] = {}

    for header in headers:
        values = [row[header] for row in rows]
        numeric_values = []
        for v in values:
            try:
                numeric_values.append(float(v))
            except (ValueError, TypeError):
                pass

        if len(numeric_values) == len(values) and numeric_values:
            stats[header] = {
                "type": "numeric",
                "count": len(numeric_values),
                "min": min(numeric_values),
                "max": max(numeric_values),
                "mean": sum(numeric_values) / len(numeric_values),
            }
        else:
            stats[header] = {
                "type": "text",
                "count": len(values),
                "unique": len(set(values)),
            }

    return stats
