"""Daily schedule planner."""

from __future__ import annotations

from typing import List

from scheduler.events import Event, hours_until


def create_daily_schedule(events: List[Event]) -> List[dict]:
    """Sort *events* by start time and compute gap hours between them.

    Returns a list of dicts:
        [{"event": <Event>, "hours_until": <float>, "gap_after": <float|None>}, ...]

    ``gap_after`` is the gap in hours between the end of this event and the
    start of the next one (``None`` for the last event).
    """
    sorted_events = sorted(events, key=lambda e: e.start_time)
    schedule = []

    for i, evt in enumerate(sorted_events):
        entry: dict = {
            "event": evt,
            "hours_until": hours_until(evt),
            "gap_after": None,
        }
        if i + 1 < len(sorted_events):
            end_time = evt.start_time.timestamp() + evt.duration * 3600
            next_start = sorted_events[i + 1].start_time.timestamp()
            entry["gap_after"] = (next_start - end_time) / 3600.0
        schedule.append(entry)

    return schedule
