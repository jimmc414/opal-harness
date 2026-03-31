import pytest
from database.setup import create_db
from database.queries import get_all_orders, get_orders_by_customer, get_order_total


@pytest.fixture
def db():
    conn = create_db()
    yield conn
    conn.close()


def test_get_all_orders(db):
    orders = get_all_orders(db)
    assert len(orders) == 7


def test_get_orders_by_customer(db):
    orders = get_orders_by_customer(db, 'Alice Smith')
    assert len(orders) == 3


def test_get_order_total(db):
    total = get_order_total(db, 1)
    assert abs(total - 29.97) < 0.01
