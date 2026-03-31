import os

ENV_MAP = {
    "APP_PORT": ("port", int),
    "APP_DEBUG": ("debug", lambda v: v.lower() in ("1", "true", "yes")),
    "APP_LOG_LEVEL": ("log_level", str),
    "APP_DB_HOST": ("db_host", str),
    "APP_WORKERS": ("workers", int),
}


def load_from_env():
    result = {}
    for env_key, (config_key, converter) in ENV_MAP.items():
        val = os.environ.get(env_key)
        if val is not None:
            result[config_key] = converter(val)
    return result
