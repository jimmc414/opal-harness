from tracker.database import get_db, create_task, get_task, get_all_tasks, update_task, delete_task, search_tasks

import pytest


@pytest.fixture
def db():
    conn = get_db()
    yield conn
    conn.close()


def test_create_task(db):
    task = create_task(db, "Test task", "A description", priority=1)
    assert task["title"] == "Test task"
    assert task["status"] == "todo"
    assert task["priority"] == 1


def test_get_task(db):
    created = create_task(db, "Find me")
    found = get_task(db, created["id"])
    assert found["title"] == "Find me"


def test_get_missing_task(db):
    assert get_task(db, 999) is None


def test_get_all_tasks(db):
    create_task(db, "Task 1")
    create_task(db, "Task 2")
    tasks = get_all_tasks(db)
    assert len(tasks) == 2


def test_filter_by_status(db):
    create_task(db, "Task 1")
    t2 = create_task(db, "Task 2")
    update_task(db, t2["id"], status="done")
    done = get_all_tasks(db, status="done")
    assert len(done) == 1
    assert done[0]["title"] == "Task 2"


def test_update_task(db):
    task = create_task(db, "Original")
    updated = update_task(db, task["id"], title="Updated", status="in_progress")
    assert updated["title"] == "Updated"
    assert updated["status"] == "in_progress"


def test_update_missing_task(db):
    assert update_task(db, 999, title="Nope") is None


def test_delete_task(db):
    task = create_task(db, "Delete me")
    deleted = delete_task(db, task["id"])
    assert deleted is not None
    assert get_task(db, task["id"]) is None


def test_delete_missing_task(db):
    assert delete_task(db, 999) is None


def test_search_tasks(db):
    create_task(db, "Buy groceries", "Milk, eggs, bread")
    create_task(db, "Fix bug", "NullPointerException in parser")
    results = search_tasks(db, "groceries")
    assert len(results) == 1
    assert results[0]["title"] == "Buy groceries"


def test_search_description(db):
    create_task(db, "Fix bug", "NullPointerException in parser")
    results = search_tasks(db, "parser")
    assert len(results) == 1
