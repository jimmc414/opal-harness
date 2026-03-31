import re


def slugify(text):
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    return text.strip('-')


def truncate(text, max_length=100, suffix='...'):
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix


def capitalize_words(text):
    return ' '.join(word.capitalize() for word in text.split())


def strip_html(text):
    return re.sub(r'<[^>]+>', '', text)
