from textproc.utils import slugify, truncate, capitalize_words, strip_html
from textproc.parser import parse_content
from textproc.validator import is_valid_slug


def test_slugify():
    assert slugify("Hello World!") == "hello-world"
    assert slugify("  Foo  Bar  ") == "foo-bar"


def test_truncate():
    assert truncate("short") == "short"
    assert len(truncate("a" * 200)) <= 100


def test_capitalize():
    assert capitalize_words("hello world") == "Hello World"


def test_strip_html():
    assert strip_html("<p>Hello</p>") == "Hello"


def test_parse_content():
    result = parse_content("<p>Hello World</p>")
    assert result == "Hello World"


def test_valid_slug():
    assert is_valid_slug("hello-world") is True
    assert is_valid_slug("Hello World!") is False
