def send_notification(channel, recipient, message, **kwargs):
    if channel == "email":
        subject = kwargs.get("subject", "Notification")
        return {
            "channel": "email",
            "to": recipient,
            "subject": subject,
            "body": message,
            "status": "sent",
        }
    elif channel == "sms":
        if len(message) > 160:
            message = message[:157] + "..."
        return {
            "channel": "sms",
            "to": recipient,
            "body": message,
            "status": "sent",
        }
    elif channel == "push":
        title = kwargs.get("title", "Alert")
        return {
            "channel": "push",
            "to": recipient,
            "title": title,
            "body": message,
            "status": "sent",
        }
    elif channel == "slack":
        slack_channel = kwargs.get("slack_channel", "#general")
        return {
            "channel": "slack",
            "to": recipient,
            "slack_channel": slack_channel,
            "body": message,
            "status": "sent",
        }
    elif channel == "webhook":
        url = kwargs.get("url")
        if url is None:
            return {"channel": "webhook", "status": "error", "reason": "missing url"}
        return {
            "channel": "webhook",
            "to": recipient,
            "url": url,
            "body": message,
            "status": "sent",
        }
    else:
        return {"channel": channel, "status": "error", "reason": "unknown channel"}
