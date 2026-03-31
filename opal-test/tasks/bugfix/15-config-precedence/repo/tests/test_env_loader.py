import os

from config.env_loader import load_from_env


class TestEnvLoader:
    def test_no_env_vars(self):
        result = load_from_env()
        assert result == {}

    def test_port(self):
        os.environ["APP_PORT"] = "9999"
        result = load_from_env()
        assert result["port"] == 9999

    def test_debug_true(self):
        os.environ["APP_DEBUG"] = "true"
        result = load_from_env()
        assert result["debug"] is True

    def test_debug_false(self):
        os.environ["APP_DEBUG"] = "no"
        result = load_from_env()
        assert result["debug"] is False

    def test_log_level(self):
        os.environ["APP_LOG_LEVEL"] = "DEBUG"
        result = load_from_env()
        assert result["log_level"] == "DEBUG"

    def test_db_host(self):
        os.environ["APP_DB_HOST"] = "remote.host"
        result = load_from_env()
        assert result["db_host"] == "remote.host"

    def test_workers(self):
        os.environ["APP_WORKERS"] = "16"
        result = load_from_env()
        assert result["workers"] == 16
