"""File server configuration."""

import os

# Base directory where uploaded files are stored.
# In production this would come from an env var or config file.
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
