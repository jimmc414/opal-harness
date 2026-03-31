from services.user_service import UserService
from services.order_service import OrderService
from services.logger import logger
from services.cache import cache
from services.mailer import mailer


def test_create_user():
    svc = UserService()
    user = svc.create_user("alice", "alice@test.com")
    assert user["username"] == "alice"
    assert cache.get("user:alice") is not None
    assert any("Created user" in log["message"] for log in logger.get_logs())


def test_get_user_cached():
    svc = UserService()
    svc.create_user("bob", "bob@test.com")
    user = svc.get_user("bob")
    assert user["username"] == "bob"
    assert any("Cache hit" in log["message"] for log in logger.get_logs())


def test_get_user_missing():
    svc = UserService()
    user = svc.get_user("nobody")
    assert user is None
    assert any("Cache miss" in log["message"] for log in logger.get_logs())


def test_delete_user():
    svc = UserService()
    svc.create_user("charlie", "charlie@test.com")
    assert svc.delete_user("charlie") is True
    assert cache.get("user:charlie") is None


def test_delete_missing_user():
    svc = UserService()
    assert svc.delete_user("nobody") is False
    assert any("not found" in log["message"] for log in logger.get_logs())


def test_create_order():
    svc = OrderService()
    order = svc.create_order("ORD-1", "alice@test.com", ["widget"])
    assert order["id"] == "ORD-1"
    assert order["status"] == "pending"
    assert cache.get("order:ORD-1") is not None
    assert len(mailer.get_sent()) == 1
    assert mailer.get_sent()[0]["subject"] == "Order Confirmation"


def test_get_order():
    svc = OrderService()
    svc.create_order("ORD-2", "bob@test.com", ["gadget"])
    order = svc.get_order("ORD-2")
    assert order is not None
    assert order["id"] == "ORD-2"


def test_get_missing_order():
    svc = OrderService()
    assert svc.get_order("FAKE") is None


def test_update_status():
    svc = OrderService()
    svc.create_order("ORD-3", "carol@test.com", ["thing"])
    updated = svc.update_status("ORD-3", "shipped")
    assert updated["status"] == "shipped"
    emails = mailer.get_sent()
    assert len(emails) == 2  # confirmation + shipped notification


def test_update_missing_order():
    svc = OrderService()
    assert svc.update_status("FAKE", "shipped") is None
