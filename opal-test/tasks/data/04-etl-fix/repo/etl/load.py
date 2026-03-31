class TargetStore:
    def __init__(self):
        self.records = []
        self.errors = []

    def add(self, record):
        self.records.append(record)

    def add_error(self, record, error):
        self.errors.append({"record": record, "error": str(error)})

    def get_all(self):
        return list(self.records)

    def get_errors(self):
        return list(self.errors)


def load(store, records):
    for record in records:
        store.add(record)
    return len(records)
