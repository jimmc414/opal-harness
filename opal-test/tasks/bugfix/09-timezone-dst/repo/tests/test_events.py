"""Tests for scheduler.events — including DST edge cases.

The DST tests mock ``datetime.now()`` to land on specific dates around
US Eastern DST transitions:

* Spring-forward 2025: Sunday 9 Mar 2025 02:00 -> 03:00
* Fall-back   2025: Sunday 2 Nov 2025 02:00 -> 01:00

We patch ``scheduler.events.datetime`` so that ``datetime.now()`` returns
a controlled value while leaving the real ``datetime`` class usable for
constructing target times.
"""

import pytest
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock
from zoneinfo import ZoneInfo

from scheduler.events import Event, hours_until
from scheduler.planner import create_daily_schedule
from scheduler.utils import parse_time


# ---------------------------------------------------------------------------
# Helper — build a patched datetime class whose .now() returns a fixed value
# ---------------------------------------------------------------------------

def _make_mock_datetime(frozen_now):
    """Return a mock that acts like the datetime *class* but with a fixed now()."""
    mock_dt = MagicMock(wraps=datetime)
    mock_dt.now = MagicMock(return_value=frozen_now)
    mock_dt.combine = datetime.combine
    mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)
    return mock_dt


# ---------------------------------------------------------------------------
# Same-day test — no DST boundary, should always pass
# ---------------------------------------------------------------------------

def test_hours_until_same_day():
    """hours_until for an event later the same day (no DST crossing)."""
    frozen_now = datetime(2025, 6, 15, 9, 0, 0)  # a summer day, no DST change
    event = Event(name="Lunch", start_time=datetime(2025, 6, 15, 12, 0, 0), duration=1.0)

    with patch("scheduler.events.datetime") as mock_dt:
        mock_dt.now = MagicMock(return_value=frozen_now)
        mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)
        result = hours_until(event)

    assert abs(result - 3.0) < 0.01, f"Expected ~3.0 h, got {result}"


# ---------------------------------------------------------------------------
# DST spring-forward: clocks jump 02:00 -> 03:00 on 9 Mar 2025
#
# "now" = 2025-03-09 00:00 EST (UTC-5)
# event = 2025-03-09 05:00 EDT (UTC-4)
#
# Wall-clock difference: 5 hours of wall time …
#   BUT only 4 real hours elapse because the clock skips 02->03.
#
# Naive subtraction gives 5.0 h.  Correct answer is 4.0 h.
# ---------------------------------------------------------------------------

def test_hours_until_dst_spring():
    """hours_until must account for spring-forward (lose 1 hour)."""
    # "now" is midnight on the morning of spring-forward
    frozen_now = datetime(2025, 3, 9, 0, 0, 0)
    # event is at 05:00 wall-clock the same day (after the 02->03 jump)
    event = Event(name="Morning run", start_time=datetime(2025, 3, 9, 5, 0, 0), duration=1.0)

    with patch("scheduler.events.datetime") as mock_dt:
        mock_dt.now = MagicMock(return_value=frozen_now)
        mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)
        result = hours_until(event)

    # Correct elapsed real-time is 4 hours (wall says 5 but 1 hour vanishes).
    assert abs(result - 4.0) < 0.05, (
        f"Spring-forward: expected ~4.0 h, got {result:.4f}. "
        "Naive subtraction gives 5.0 — DST not handled."
    )


# ---------------------------------------------------------------------------
# DST fall-back: clocks repeat 02:00 -> 01:00 on 2 Nov 2025
#
# "now" = 2025-11-01 23:00 EDT (UTC-4)
# event = 2025-11-02 03:00 EST (UTC-5)
#
# Wall-clock difference: 4 hours …
#   BUT 5 real hours elapse because the clock repeats 01:00-02:00.
#
# Naive subtraction gives 4.0 h.  Correct answer is 5.0 h.
# ---------------------------------------------------------------------------

def test_hours_until_dst_fall():
    """hours_until must account for fall-back (gain 1 hour)."""
    # "now" is 23:00 on 1 Nov (still EDT)
    frozen_now = datetime(2025, 11, 1, 23, 0, 0)
    # event is 03:00 on 2 Nov (after fall-back, now EST)
    event = Event(name="Early meeting", start_time=datetime(2025, 11, 2, 3, 0, 0), duration=0.5)

    with patch("scheduler.events.datetime") as mock_dt:
        mock_dt.now = MagicMock(return_value=frozen_now)
        mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)
        result = hours_until(event)

    # Correct elapsed real-time is 5 hours (wall says 4 but 1 hour repeats).
    assert abs(result - 5.0) < 0.05, (
        f"Fall-back: expected ~5.0 h, got {result:.4f}. "
        "Naive subtraction gives 4.0 — DST not handled."
    )


# ---------------------------------------------------------------------------
# Schedule creation — cross-DST
# ---------------------------------------------------------------------------

def test_create_schedule_same_day():
    """create_daily_schedule for events on the same non-DST day."""
    frozen_now = datetime(2025, 6, 15, 8, 0, 0)
    events = [
        Event("A", datetime(2025, 6, 15, 10, 0), 1.0),
        Event("B", datetime(2025, 6, 15, 12, 0), 1.5),
    ]
    with patch("scheduler.events.datetime") as mock_dt:
        mock_dt.now = MagicMock(return_value=frozen_now)
        mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)
        schedule = create_daily_schedule(events)

    assert len(schedule) == 2
    assert abs(schedule[0]["hours_until"] - 2.0) < 0.05
    assert abs(schedule[1]["hours_until"] - 4.0) < 0.05


def test_create_schedule_across_dst():
    """create_daily_schedule spanning a spring-forward transition."""
    frozen_now = datetime(2025, 3, 9, 0, 0, 0)
    events = [
        Event("Pre-DST", datetime(2025, 3, 9, 1, 0), 0.5),
        Event("Post-DST", datetime(2025, 3, 9, 5, 0), 1.0),
    ]
    with patch("scheduler.events.datetime") as mock_dt:
        mock_dt.now = MagicMock(return_value=frozen_now)
        mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)
        schedule = create_daily_schedule(events)

    # Pre-DST event: 1 hour wall = 1 hour real (no crossing yet)
    assert abs(schedule[0]["hours_until"] - 1.0) < 0.05
    # Post-DST event: 5 hours wall but only 4 real hours
    assert abs(schedule[1]["hours_until"] - 4.0) < 0.05, (
        f"Expected ~4.0 h for post-DST event, got {schedule[1]['hours_until']:.4f}"
    )


# ---------------------------------------------------------------------------
# parse_time must return local-tz-aware datetime, not UTC
# ---------------------------------------------------------------------------

def test_parse_time_local_tz():
    """parse_time('14:30') must produce a time in the local timezone, not UTC.

    After the fix, if the system TZ is America/New_York, the result should
    carry the Eastern offset (UTC-5 or UTC-4 depending on date), not UTC+0.
    """
    result = parse_time("14:30")

    # The result must be timezone-aware
    assert result.tzinfo is not None, (
        "parse_time returned a naive datetime — it must be timezone-aware"
    )

    # And it must NOT be UTC (offset should be -5 or -4 for Eastern)
    utc_offset_hours = result.utcoffset().total_seconds() / 3600
    assert utc_offset_hours != 0, (
        f"parse_time returned UTC (offset 0). Expected local tz offset, "
        f"got {utc_offset_hours}"
    )
