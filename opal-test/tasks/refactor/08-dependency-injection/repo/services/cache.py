class Cache:
    def __init__(self):
        self._store = {}

    def get(self, key):
        return self._store.get(key)

    def set(self, key, value):
        self._store[key] = value

    def delete(self, key):
        return self._store.pop(key, None)

    def clear(self):
        self._store.clear()

    def size(self):
        return len(self._store)


cache = Cache()
