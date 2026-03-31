import os

from config.loader import load_config


class TestDefaultsOnly:
    def test_defaults_when_no_sources(self):
        cfg = load_config()
        assert cfg["port"] == 8080
        assert cfg["debug"] is False
        assert cfg["log_level"] == "INFO"
        assert cfg["db_host"] == "localhost"
        assert cfg["workers"] == 4


class TestFileOverridesDefaults:
    def test_file_overrides_all_defaults(self, config_path):
        cfg = load_config(config_file=config_path)
        assert cfg["port"] == 3000
        assert cfg["debug"] is True
        assert cfg["log_level"] == "WARNING"
        assert cfg["db_host"] == "db.example.com"
        assert cfg["workers"] == 8


class TestEnvOverridesFile:
    def test_env_overrides_log_level(self, config_path):
        os.environ["APP_LOG_LEVEL"] = "ERROR"
        cfg = load_config(config_file=config_path)
        assert cfg["log_level"] == "ERROR"

    def test_env_overrides_port(self, config_path):
        os.environ["APP_PORT"] = "9999"
        cfg = load_config(config_file=config_path)
        assert cfg["port"] == 9999

    def test_env_overrides_debug(self, config_path):
        os.environ["APP_DEBUG"] = "0"
        cfg = load_config(config_file=config_path)
        assert cfg["debug"] is False


class TestCliOverridesAll:
    def test_cli_overrides_env_and_file(self, config_path):
        os.environ["APP_PORT"] = "9999"
        os.environ["APP_LOG_LEVEL"] = "ERROR"
        cfg = load_config(
            config_file=config_path,
            cli_argv=["--port", "1111", "--log-level", "CRITICAL"],
        )
        assert cfg["port"] == 1111
        assert cfg["log_level"] == "CRITICAL"

    def test_cli_overrides_defaults(self):
        cfg = load_config(cli_argv=["--workers", "32"])
        assert cfg["workers"] == 32


class TestFullPrecedence:
    def test_full_precedence_cli_wins(self, config_path):
        os.environ["APP_PORT"] = "9999"
        os.environ["APP_DEBUG"] = "0"
        os.environ["APP_LOG_LEVEL"] = "ERROR"
        cfg = load_config(
            config_file=config_path,
            cli_argv=["--port", "7777", "--debug"],
        )
        assert cfg["port"] == 7777
        assert cfg["debug"] is True
        assert cfg["log_level"] == "ERROR"

    def test_full_precedence_env_wins_over_file(self, config_path):
        os.environ["APP_PORT"] = "5555"
        os.environ["APP_DEBUG"] = "0"
        os.environ["APP_DB_HOST"] = "env.host"
        os.environ["APP_WORKERS"] = "12"
        cfg = load_config(config_file=config_path)
        assert cfg["port"] == 5555
        assert cfg["debug"] is False
        assert cfg["db_host"] == "env.host"
        assert cfg["workers"] == 12
