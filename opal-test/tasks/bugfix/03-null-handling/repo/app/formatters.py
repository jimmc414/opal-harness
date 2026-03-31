"""User data formatting utilities."""


def format_user(user):
    """Format a user dict for API response.

    Normalizes email to lowercase and builds a display name.

    Args:
        user: Dict with user data from the database.

    Returns:
        Dict formatted for the JSON response.
    """
    return {
        "id": user["id"],
        "display_name": f"{user['first_name']} {user['last_name']}",
        "email": user["email"].lower(),
        "age": user["age"],
    }
