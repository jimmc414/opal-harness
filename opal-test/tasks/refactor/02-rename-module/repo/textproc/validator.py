from textproc.utils import slugify


def is_valid_slug(text):
    return text == slugify(text)


def sanitize_input(text):
    return text.strip()
