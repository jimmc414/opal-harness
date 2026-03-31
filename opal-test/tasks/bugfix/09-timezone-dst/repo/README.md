# Scheduler

A lightweight event-scheduling library for computing time-until-event,
building daily schedules, and formatting durations.

## Usage

```python
from datetime import datetime
from scheduler.events import Event, hours_until

evt = Event(name="Standup", start_time=datetime(2025, 6, 15, 9, 0), duration=0.5)
print(hours_until(evt))  # hours from now until 09:00
```

## Modules

| Module | Purpose |
|--------|---------|
| `scheduler.events` | `Event` dataclass, `hours_until` computation |
| `scheduler.planner` | `create_daily_schedule` — sort events and compute gaps |
| `scheduler.utils` | `parse_time`, `format_duration` helpers |

## Running Tests

```bash
pytest tests/ -v
```
