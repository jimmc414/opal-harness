from config.file_loader import load_from_file


class TestFileLoader:
    def test_loads_port(self, config_path):
        data = load_from_file(config_path)
        assert data["port"] == 3000

    def test_loads_debug(self, config_path):
        data = load_from_file(config_path)
        assert data["debug"] is True

    def test_loads_log_level(self, config_path):
        data = load_from_file(config_path)
        assert data["log_level"] == "WARNING"

    def test_loads_db_host(self, config_path):
        data = load_from_file(config_path)
        assert data["db_host"] == "db.example.com"

    def test_loads_workers(self, config_path):
        data = load_from_file(config_path)
        assert data["workers"] == 8
