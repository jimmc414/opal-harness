from pipeline.export import write_output


class TestExport:
    def test_write_ascii_content(self, tmp_output):
        write_output(["hello", "world"], tmp_output)
        with open(tmp_output, encoding='utf-8') as f:
            content = f.read()
        assert "hello\n" in content
        assert "world\n" in content

    def test_write_unicode_content(self, tmp_output):
        write_output(["café", "résumé", "straße"], tmp_output)
        with open(tmp_output, encoding='utf-8') as f:
            lines = [l.rstrip('\n') for l in f.readlines()]
        assert "café" in lines
        assert "résumé" in lines
        assert "straße" in lines

    def test_output_line_count(self, tmp_output):
        write_output(["a", "b", "c"], tmp_output)
        with open(tmp_output, encoding='utf-8') as f:
            lines = f.readlines()
        assert len(lines) == 3
