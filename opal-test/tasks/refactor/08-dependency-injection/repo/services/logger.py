class Logger:
    def __init__(self):
        self.logs = []

    def info(self, message):
        self.logs.append({"level": "info", "message": message})

    def error(self, message):
        self.logs.append({"level": "error", "message": message})

    def get_logs(self):
        return list(self.logs)

    def clear(self):
        self.logs.clear()


logger = Logger()
