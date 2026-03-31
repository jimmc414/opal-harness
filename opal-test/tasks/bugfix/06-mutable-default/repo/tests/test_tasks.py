"""Tests for taskqueue.tasks module."""

import pytest
from taskqueue.tasks import create_task, create_batch, update_task_status


class TestCreateTask:
    """Tests for the create_task function."""

    def test_single_task(self):
        """A single task with explicit tags should work fine."""
        task = create_task("deploy", tags=["prod"])
        assert task["name"] == "deploy"
        assert task["tags"] == ["prod"]
        assert task["status"] == "pending"
        assert "id" in task

    def test_task_with_explicit_tags(self):
        """Explicit tags should be set correctly."""
        task = create_task("build", tags=["ci", "docker"])
        assert task["tags"] == ["ci", "docker"]

    def test_multiple_tasks_no_shared_tags(self):
        """Tags must NOT leak between independent create_task calls.

        This is the core mutable default argument test:
        calling create_task with tags, then without, should give
        the second task an empty tags list.
        """
        task_a = create_task("first", tags=["alpha", "beta"])
        task_b = create_task("second")

        # task_b should have empty tags, not ["alpha", "beta"]
        assert task_b["tags"] == [], (
            f"Tags leaked from task_a to task_b: {task_b['tags']}"
        )

        # Also verify task_a is unchanged
        assert task_a["tags"] == ["alpha", "beta"]

    def test_default_tags_are_independent(self):
        """Each call with default tags should get its own list."""
        task_x = create_task("x")
        task_y = create_task("y")
        task_x["tags"].append("mutated")

        # Mutating task_x's tags should not affect task_y
        assert task_y["tags"] == [], (
            f"Mutating task_x tags affected task_y: {task_y['tags']}"
        )

    def test_explicit_tags_defensive_copy(self):
        """Caller's tag list should be independent from the task's tags.

        After creating a task with an explicit tags list, mutating
        the caller's list must not affect the task, and vice versa.
        """
        my_tags = ["web", "api"]
        task = create_task("service", tags=my_tags)

        # Mutate the caller's list
        my_tags.append("extra")

        # Task should not be affected
        assert task["tags"] == ["web", "api"], (
            f"Caller mutation affected task: {task['tags']}"
        )

        # Mutate the task's list
        task["tags"].append("internal")

        # Caller should not be affected
        assert my_tags == ["web", "api", "extra"], (
            f"Task mutation affected caller: {my_tags}"
        )


class TestCreateBatch:
    """Tests for the create_batch function."""

    def test_batch_creation(self):
        """Basic batch creation should work."""
        batch = create_batch(["t1", "t2"], metadata={"env": "test"})
        assert len(batch["tasks"]) == 2
        assert batch["metadata"] == {"env": "test"}
        assert "batch_id" in batch

    def test_batch_independence(self):
        """Metadata must NOT leak between independent create_batch calls.

        This is the dict version of the mutable default argument bug.
        """
        batch_a = create_batch(["a"], metadata={"suite": "integration"})
        batch_b = create_batch(["b"])

        # batch_b should have empty metadata, not {"suite": "integration"}
        assert batch_b["metadata"] == {}, (
            f"Metadata leaked from batch_a to batch_b: {batch_b['metadata']}"
        )

    def test_default_metadata_independent(self):
        """Each call with default metadata should get its own dict."""
        batch_x = create_batch(["x"])
        batch_y = create_batch(["y"])
        batch_x["metadata"]["injected"] = "value"

        assert batch_y["metadata"] == {}, (
            f"Mutating batch_x metadata affected batch_y: {batch_y['metadata']}"
        )

    def test_explicit_metadata_defensive_copy(self):
        """Caller's metadata dict must be independent from the batch's."""
        my_meta = {"version": "1.0"}
        batch = create_batch(["svc"], metadata=my_meta)

        # Mutate caller's dict
        my_meta["added"] = "later"

        # Batch should not be affected
        assert batch["metadata"] == {"version": "1.0"}, (
            f"Caller mutation affected batch: {batch['metadata']}"
        )


class TestUpdateTaskStatus:
    """Tests for the update_task_status function."""

    def test_valid_status_update(self):
        task = create_task("job")
        updated = update_task_status(task, "running")
        assert updated["status"] == "running"

    def test_invalid_status(self):
        task = create_task("job")
        with pytest.raises(ValueError, match="Invalid status"):
            update_task_status(task, "bogus")
