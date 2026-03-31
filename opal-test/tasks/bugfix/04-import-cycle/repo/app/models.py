"""Data models for the application."""

from dataclasses import dataclass
from .validators import validate_email


@dataclass
class User:
    """A user in the system."""
    name: str
    email: str

    def is_valid(self):
        """Check if the user's email is valid."""
        return validate_email(self.email)


@dataclass
class Order:
    """An order placed by a user."""
    user: User
    item: str
    quantity: int
    price_cents: int

    def total_cents(self):
        """Calculate total price in cents."""
        return self.quantity * self.price_cents
