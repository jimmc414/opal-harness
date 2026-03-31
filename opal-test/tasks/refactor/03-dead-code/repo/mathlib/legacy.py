import datetime
import hashlib


def old_hash(data):
    return hashlib.md5(data.encode()).hexdigest()


def format_date(dt):
    return dt.strftime("%Y-%m-%d")


class OldProcessor:
    def __init__(self):
        self.cache = {}

    def process(self, data):
        key = old_hash(str(data))
        if key in self.cache:
            return self.cache[key]
        result = data * 2
        self.cache[key] = result
        return result
