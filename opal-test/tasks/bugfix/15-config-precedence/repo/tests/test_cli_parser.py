from config.cli_parser import parse_cli_args


class TestCliParser:
    def test_no_args(self):
        result = parse_cli_args(None)
        assert result == {}

    def test_empty_list(self):
        result = parse_cli_args([])
        assert result == {}

    def test_port(self):
        result = parse_cli_args(["--port", "5000"])
        assert result["port"] == 5000

    def test_debug(self):
        result = parse_cli_args(["--debug"])
        assert result["debug"] is True

    def test_log_level(self):
        result = parse_cli_args(["--log-level", "ERROR"])
        assert result["log_level"] == "ERROR"

    def test_db_host(self):
        result = parse_cli_args(["--db-host", "cli.host"])
        assert result["db_host"] == "cli.host"

    def test_workers(self):
        result = parse_cli_args(["--workers", "2"])
        assert result["workers"] == 2

    def test_multiple_args(self):
        result = parse_cli_args(["--port", "5000", "--debug", "--workers", "2"])
        assert result["port"] == 5000
        assert result["debug"] is True
        assert result["workers"] == 2

    def test_unknown_args_ignored(self):
        result = parse_cli_args(["--unknown", "value", "--port", "5000"])
        assert result == {"port": 5000}
