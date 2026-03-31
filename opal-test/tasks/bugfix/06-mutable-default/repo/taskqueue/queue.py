"""Task queue with priority-based ordering."""

from typing import Dict, Any, List, Optional
from .priority import calculate_priority


class TaskQueue:
    """A simple priority-based task queue."""

    def __init__(self):
        self._tasks: List[Dict[str, Any]] = []

    def add(self, task: Dict[str, Any]) -> None:
        """Add a task to the queue."""
        self._tasks.append(task)
        self._tasks.sort(key=lambda t: calculate_priority(t), reverse=True)

    def remove(self, task_id: str) -> Optional[Dict[str, Any]]:
        """Remove and return a task by ID. Returns None if not found."""
        for i, task in enumerate(self._tasks):
            if task["id"] == task_id:
                return self._tasks.pop(i)
        return None

    def peek(self) -> Optional[Dict[str, Any]]:
        """Return the highest-priority task without removing it."""
        return self._tasks[0] if self._tasks else None

    def pop(self) -> Optional[Dict[str, Any]]:
        """Remove and return the highest-priority task."""
        return self._tasks.pop(0) if self._tasks else None

    def list(self) -> List[Dict[str, Any]]:
        """Return all tasks in priority order."""
        return list(self._tasks)

    def size(self) -> int:
        """Return the number of tasks in the queue."""
        return len(self._tasks)

    def clear(self) -> None:
        """Remove all tasks from the queue."""
        self._tasks.clear()
