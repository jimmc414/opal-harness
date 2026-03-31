"""Task and batch creation utilities."""

import uuid
from typing import List, Dict, Any, Optional


def create_task(name: str, tags: List[str] = [], priority: int = 0) -> Dict[str, Any]:
    """Create a new task dictionary.

    Args:
        name: The task name.
        tags: List of string tags for categorization.
        priority: Integer priority (higher = more urgent).

    Returns:
        Dictionary representing the task.
    """

    return {
        "id": str(uuid.uuid4()),
        "name": name,
        "tags": tags,
        "priority": priority,
        "status": "pending",
    }


def create_batch(
    names: List[str],
    metadata: Dict[str, str] = {},
    priority: int = 0,
) -> Dict[str, Any]:
    """Create a batch of tasks sharing common metadata.

    Args:
        names: List of task names to create in the batch.
        metadata: Shared metadata dict for all tasks in the batch.
        priority: Default priority for all tasks in the batch.

    Returns:
        Dictionary with batch_id, metadata, and list of tasks.
    """

    tasks = []
    for name in names:
        task = create_task(name, priority=priority)
        tasks.append(task)

    return {
        "batch_id": str(uuid.uuid4()),
        "metadata": metadata,
        "tasks": tasks,
    }


def update_task_status(task: Dict[str, Any], status: str) -> Dict[str, Any]:
    """Update a task's status.

    Args:
        task: The task dictionary.
        status: New status string (pending, running, completed, failed).

    Returns:
        Updated task dictionary.
    """
    valid_statuses = {"pending", "running", "completed", "failed"}
    if status not in valid_statuses:
        raise ValueError(f"Invalid status '{status}'. Must be one of: {valid_statuses}")
    task["status"] = status
    return task
