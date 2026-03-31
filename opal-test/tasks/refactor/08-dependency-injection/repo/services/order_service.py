from services.logger import logger
from services.cache import cache
from services.mailer import mailer


class OrderService:
    def create_order(self, order_id, customer_email, items):
        order = {"id": order_id, "customer": customer_email, "items": items, "status": "pending"}
        cache.set(f"order:{order_id}", order)
        logger.info(f"Order created: {order_id}")
        mailer.send(customer_email, "Order Confirmation", f"Order {order_id} received")
        return order

    def get_order(self, order_id):
        order = cache.get(f"order:{order_id}")
        if order:
            logger.info(f"Found order: {order_id}")
        else:
            logger.info(f"Order not found: {order_id}")
        return order

    def update_status(self, order_id, status):
        order = cache.get(f"order:{order_id}")
        if order is None:
            logger.error(f"Order not found for status update: {order_id}")
            return None
        order["status"] = status
        cache.set(f"order:{order_id}", order)
        logger.info(f"Order {order_id} status: {status}")
        if status == "shipped":
            mailer.send(order["customer"], "Order Shipped", f"Order {order_id} has shipped")
        return order
