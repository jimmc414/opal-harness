class EntityStore:
    def __init__(self):
        self._data = {}

    def add(self, entity):
        self._data[entity.id] = entity
        return entity

    def get(self, entity_id):
        return self._data.get(entity_id)

    def remove(self, entity_id):
        return self._data.pop(entity_id, None)

    def all(self):
        return list(self._data.values())

    def count(self):
        return len(self._data)
