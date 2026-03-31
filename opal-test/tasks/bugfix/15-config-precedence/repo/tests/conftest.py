import os
import pytest


@pytest.fixture(autouse=True)
def clean_env():
    env_keys = ["APP_PORT", "APP_DEBUG", "APP_LOG_LEVEL", "APP_DB_HOST", "APP_WORKERS"]
    old_values = {}
    for key in env_keys:
        if key in os.environ:
            old_values[key] = os.environ.pop(key)
    yield
    for key in env_keys:
        if key in os.environ:
            del os.environ[key]
    for key, val in old_values.items():
        os.environ[key] = val


@pytest.fixture
def config_path():
    return os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "fixtures", "sample_config.json"
    )
