from db.queries import create_user, get_user, get_all_users, update_user, delete_user


def test_create_user(conn):
    uid = create_user(conn, "alice", "alice@example.com")
    assert uid == 1


def test_get_user(conn):
    create_user(conn, "bob", "bob@example.com")
    user = get_user(conn, 1)
    assert user["username"] == "bob"
    assert user["email"] == "bob@example.com"


def test_get_all_users(conn):
    create_user(conn, "alice", "alice@example.com")
    create_user(conn, "bob", "bob@example.com")
    users = get_all_users(conn)
    assert len(users) == 2


def test_update_user(conn):
    create_user(conn, "alice", "alice@example.com")
    user = update_user(conn, 1, email="newalice@example.com")
    assert user["email"] == "newalice@example.com"


def test_delete_user(conn):
    create_user(conn, "alice", "alice@example.com")
    deleted = delete_user(conn, 1)
    assert deleted is not None
    assert get_user(conn, 1) is None
