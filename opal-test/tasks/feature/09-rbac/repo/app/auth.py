USERS = {
    "token-admin-1": {"id": 1, "username": "admin", "role": "admin"},
    "token-editor-1": {"id": 2, "username": "editor", "role": "editor"},
    "token-viewer-1": {"id": 3, "username": "viewer", "role": "viewer"},
}


def get_user_from_token(token):
    return USERS.get(token)
