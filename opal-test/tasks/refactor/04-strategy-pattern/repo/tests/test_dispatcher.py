from notify.dispatcher import send_notification


def test_email():
    result = send_notification("email", "user@test.com", "Hello", subject="Test")
    assert result["channel"] == "email"
    assert result["to"] == "user@test.com"
    assert result["subject"] == "Test"
    assert result["status"] == "sent"


def test_email_default_subject():
    result = send_notification("email", "user@test.com", "Hello")
    assert result["subject"] == "Notification"


def test_sms():
    result = send_notification("sms", "+1234567890", "Short msg")
    assert result["channel"] == "sms"
    assert result["status"] == "sent"


def test_sms_truncation():
    long_msg = "x" * 200
    result = send_notification("sms", "+1234567890", long_msg)
    assert len(result["body"]) <= 160
    assert result["body"].endswith("...")


def test_push():
    result = send_notification("push", "device-123", "Alert!", title="Warning")
    assert result["channel"] == "push"
    assert result["title"] == "Warning"


def test_push_default_title():
    result = send_notification("push", "device-123", "Alert!")
    assert result["title"] == "Alert"


def test_slack():
    result = send_notification("slack", "user", "Message", slack_channel="#dev")
    assert result["channel"] == "slack"
    assert result["slack_channel"] == "#dev"


def test_slack_default_channel():
    result = send_notification("slack", "user", "Message")
    assert result["slack_channel"] == "#general"


def test_webhook():
    result = send_notification("webhook", "service", "Data", url="http://example.com/hook")
    assert result["channel"] == "webhook"
    assert result["url"] == "http://example.com/hook"
    assert result["status"] == "sent"


def test_webhook_missing_url():
    result = send_notification("webhook", "service", "Data")
    assert result["status"] == "error"
    assert result["reason"] == "missing url"


def test_unknown_channel():
    result = send_notification("pigeon", "bird", "Coo")
    assert result["status"] == "error"
    assert result["reason"] == "unknown channel"
