"""Event model and time-until computation."""

from dataclasses import dataclass
from datetime import datetime


@dataclass
class Event:
    """A scheduled event."""
    name: str
    start_time: datetime   # expected to be a naive local datetime
    duration: float        # hours


def hours_until(event: Event) -> float:
    """Return the number of hours from now until *event* starts.

    Negative values mean the event is in the past.

    """
    now = datetime.now()
    delta = event.start_time - now
    return delta.total_seconds() / 3600.0
