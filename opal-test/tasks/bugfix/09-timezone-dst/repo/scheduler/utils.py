"""Utility helpers for parsing and formatting times."""

from datetime import datetime, time


def parse_time(time_str: str) -> datetime:
    """Parse a time string like ``"14:30"`` into a `datetime` for today.

    The returned datetime is **naive** and represents the given time in the
    local timezone (i.e., whatever the system clock says "today" is).
    """
    parts = time_str.strip().split(":")
    hour = int(parts[0])
    minute = int(parts[1]) if len(parts) > 1 else 0
    second = int(parts[2]) if len(parts) > 2 else 0

    today = datetime.now().date()
    return datetime.combine(today, time(hour, minute, second))


def format_duration(hours: float) -> str:
    """Format a duration given in fractional hours into ``'Xh Ym'`` form.

    Examples
    --------
    >>> format_duration(2.5)
    '2h 30m'
    >>> format_duration(0.25)
    '0h 15m'
    """
    total_minutes = round(hours * 60)
    h = total_minutes // 60
    m = total_minutes % 60
    return f"{h}h {m}m"
