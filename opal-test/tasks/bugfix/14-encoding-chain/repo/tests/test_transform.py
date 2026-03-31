from pipeline.transform import normalize


class TestTransform:
    def test_lowercases(self):
        result = normalize(["HELLO", "World"])
        assert result == ["hello", "world"]

    def test_strips_whitespace(self):
        result = normalize(["  padded  ", "\ttabbed\t"])
        assert result == ["padded", "tabbed"]

    def test_removes_empty_lines(self):
        result = normalize(["hello", "", "  ", "world"])
        assert result == ["hello", "world"]

    def test_preserves_accented_characters(self):
        result = normalize(["Café", "Résumé", "Crème"])
        assert "café" in result
        assert "résumé" in result
        assert "crème" in result

    def test_preserves_german_characters(self):
        result = normalize(["Straße", "François"])
        assert "straße" in result
        assert "françois" in result
