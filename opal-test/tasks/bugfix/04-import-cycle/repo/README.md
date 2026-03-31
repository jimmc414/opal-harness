# App

A Python application with user models, validators, and utility helpers.

## Modules

- `app.models` — `User` and `Order` dataclasses
- `app.validators` — Email and order validation functions
- `app.helpers` — String normalization and currency formatting

## Usage

```python
from app.models import User, Order
from app.validators import validate_email
from app.helpers import normalize_string, format_currency

user = User(name="Alice", email="alice@example.com")
assert validate_email(user.email)

order = Order(user=user, item="Widget", quantity=2, price_cents=1500)
print(format_currency(order.price_cents))  # "$15.00"
```

## Running Tests

```bash
pytest tests/ -x -q
```
