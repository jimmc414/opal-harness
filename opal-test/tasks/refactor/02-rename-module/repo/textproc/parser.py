from textproc.utils import strip_html, truncate


def parse_content(html_text, max_length=200):
    clean = strip_html(html_text)
    return truncate(clean, max_length)
