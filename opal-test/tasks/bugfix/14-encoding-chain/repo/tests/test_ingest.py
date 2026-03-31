from pipeline.ingest import read_file


class TestIngest:
    def test_read_utf8(self, utf8_path):
        lines = read_file(utf8_path)
        assert len(lines) == 3
        assert "café" in lines
        assert "résumé" in lines

    def test_read_latin1(self, latin1_path):
        lines = read_file(latin1_path)
        assert len(lines) == 3
        assert "René" in lines
        assert "Straße" in lines
        assert "François" in lines

    def test_strips_trailing_newlines(self, utf8_path):
        lines = read_file(utf8_path)
        for line in lines:
            assert not line.endswith('\n')
