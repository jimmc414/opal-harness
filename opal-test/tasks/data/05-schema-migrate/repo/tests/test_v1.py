import pytest
from db.v1_schema import create_v1
import sqlite3


@pytest.fixture
def v1_db():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    create_v1(conn)
    yield conn
    conn.close()


def test_users_count(v1_db):
    count = v1_db.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    assert count == 4


def test_purchases_count(v1_db):
    count = v1_db.execute("SELECT COUNT(*) FROM purchases").fetchone()[0]
    assert count == 6


def test_user_alice(v1_db):
    row = v1_db.execute("SELECT * FROM users WHERE user_id = 1").fetchone()
    assert dict(row)['first_name'] == 'Alice'
    assert dict(row)['email_addr'] == 'alice@example.com'
