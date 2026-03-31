# services

Application services for user management and order processing.

## Usage

```python
from services.user_service import UserService
from services.order_service import OrderService

svc = UserService()
svc.create_user("alice", "alice@example.com")
```

## Testing

```bash
pytest tests/
```
