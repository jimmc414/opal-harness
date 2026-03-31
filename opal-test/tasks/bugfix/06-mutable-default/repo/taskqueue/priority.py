"""Priority calculation for tasks."""

from typing import Dict, Any


def calculate_priority(task: Dict[str, Any]) -> float:
    """Calculate effective priority score for a task.

    Base priority is the task's priority field. Bonus points are added
    for having tags (more specific tasks are slightly more urgent)
    and for being in certain statuses.

    Args:
        task: Task dictionary.

    Returns:
        Float priority score (higher = more urgent).
    """
    base = task.get("priority", 0)
    tag_bonus = len(task.get("tags", [])) * 0.1
    status_bonus = 0.0
    if task.get("status") == "running":
        status_bonus = 0.5  # running tasks get a small boost

    return float(base) + tag_bonus + status_bonus
