# taskqueue

A lightweight Python task queue library for creating, managing, and prioritizing tasks.

## Features

- Create individual tasks with names and tags
- Create batches of tasks with shared metadata
- Priority-based task queue with add/remove/list operations
- Priority scoring based on task attributes

## Usage

```python
from taskqueue.tasks import create_task, create_batch
from taskqueue.queue import TaskQueue

task = create_task("deploy-app", tags=["production", "urgent"])
batch = create_batch(["test-1", "test-2"], metadata={"suite": "integration"})

q = TaskQueue()
q.add(task)
print(q.list())
```

## Project Structure

```
taskqueue/
    __init__.py
    tasks.py       # Task and batch creation
    queue.py        # TaskQueue class
    priority.py     # Priority calculation
tests/
    conftest.py
    test_tasks.py
```

## Running Tests

```bash
pytest tests/ -v
```
