from pipeline.ingest import read_file
from pipeline.transform import normalize
from pipeline.export import write_output


class TestEndToEnd:
    def test_utf8_roundtrip(self, utf8_path, tmp_output):
        lines = read_file(utf8_path)
        transformed = normalize(lines)
        write_output(transformed, tmp_output)

        with open(tmp_output, encoding='utf-8') as f:
            output_lines = [l.rstrip('\n') for l in f.readlines()]

        assert "café" in output_lines
        assert "crème" in output_lines
        assert "résumé" in output_lines

    def test_latin1_roundtrip(self, latin1_path, tmp_output):
        lines = read_file(latin1_path)
        transformed = normalize(lines)
        write_output(transformed, tmp_output)

        with open(tmp_output, encoding='utf-8') as f:
            output_lines = [l.rstrip('\n') for l in f.readlines()]

        assert "rené" in output_lines
        assert "straße" in output_lines
        assert "françois" in output_lines

    def test_output_preserves_all_lines(self, utf8_path, tmp_output):
        lines = read_file(utf8_path)
        transformed = normalize(lines)
        write_output(transformed, tmp_output)

        with open(tmp_output, encoding='utf-8') as f:
            output_lines = [l.rstrip('\n') for l in f.readlines() if l.strip()]

        assert len(output_lines) == 3
