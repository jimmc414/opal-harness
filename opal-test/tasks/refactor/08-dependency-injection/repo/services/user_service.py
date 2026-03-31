from services.logger import logger
from services.cache import cache


class UserService:
    def create_user(self, username, email):
        user = {"username": username, "email": email}
        cache.set(f"user:{username}", user)
        logger.info(f"Created user: {username}")
        return user

    def get_user(self, username):
        cached = cache.get(f"user:{username}")
        if cached:
            logger.info(f"Cache hit for user: {username}")
            return cached
        logger.info(f"Cache miss for user: {username}")
        return None

    def delete_user(self, username):
        user = cache.get(f"user:{username}")
        if user is None:
            logger.error(f"User not found: {username}")
            return False
        cache.delete(f"user:{username}")
        logger.info(f"Deleted user: {username}")
        return True
