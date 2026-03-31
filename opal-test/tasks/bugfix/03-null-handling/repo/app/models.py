"""In-memory user data store."""

# Simulated database of users
_USERS = [
    {
        "id": 1,
        "first_name": "Alice",
        "last_name": "Smith",
        "email": "Alice.Smith@Example.COM",
        "age": 30,
    },
    {
        "id": 2,
        "first_name": "Bob",
        "last_name": "Jones",
        "email": "BOB.JONES@example.com",
        "age": 25,
    },
    {
        "id": 3,
        "first_name": "Charlie",
        "last_name": "Brown",
        "email": None,  # No email on file
        "age": 35,
    },
    {
        "id": 4,
        "first_name": "Diana",
        "last_name": "Prince",
        "email": "Diana.Prince@Example.com",
        "age": 28,
    },
    {
        "id": 5,
        "first_name": "Eve",
        "last_name": "Taylor",
        "email": None,  # No email on file
        "age": 22,
    },
]


def get_user(user_id):
    """Retrieve a user by ID.

    Args:
        user_id: Integer user ID.

    Returns:
        A dict with user data, or None if not found.
    """
    for user in _USERS:
        if user["id"] == user_id:
            return dict(user)  # Return a copy
    return None


def get_all_users():
    """Return all users.

    Returns:
        List of user dicts.
    """
    return [dict(u) for u in _USERS]
