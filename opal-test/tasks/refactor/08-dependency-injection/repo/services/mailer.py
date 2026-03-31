class Mailer:
    def __init__(self):
        self.sent = []

    def send(self, to, subject, body):
        email = {"to": to, "subject": subject, "body": body}
        self.sent.append(email)
        return True

    def get_sent(self):
        return list(self.sent)

    def clear(self):
        self.sent.clear()


mailer = Mailer()
