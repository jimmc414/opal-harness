from config.defaults import get_defaults


class TestDefaults:
    def test_default_port(self):
        d = get_defaults()
        assert d["port"] == 8080

    def test_default_debug(self):
        d = get_defaults()
        assert d["debug"] is False

    def test_default_log_level(self):
        d = get_defaults()
        assert d["log_level"] == "INFO"

    def test_default_db_host(self):
        d = get_defaults()
        assert d["db_host"] == "localhost"

    def test_default_workers(self):
        d = get_defaults()
        assert d["workers"] == 4

    def test_returns_new_dict_each_call(self):
        d1 = get_defaults()
        d2 = get_defaults()
        assert d1 is not d2
