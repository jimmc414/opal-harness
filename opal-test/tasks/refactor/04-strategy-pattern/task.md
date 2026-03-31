# Replace Notification Dispatch with Extensible Design

## Source

Synthetic notification system with a monolithic dispatch function.

## Problem

The `send_notification` function in `notify/dispatcher.py` uses a long if/elif chain to dispatch notifications to different channels (email, sms, push, slack, webhook). Adding a new channel requires modifying the function body. The dispatch logic should be restructured so that each channel is handled independently and new channels can be added without modifying the core dispatch function.

## Acceptance Criteria

- Replace the if/elif dispatch with a strategy or registry pattern
- Each notification channel is a separate callable or class
- `send_notification` still works with the same signature and returns identical results for all channels
- New channels can be added without modifying `send_notification`
- The dispatcher module does not contain if/elif chains on channel names
- Unknown channel handling still returns the error dict
- The webhook missing-url error case still works correctly
- All existing tests pass with no modifications to test files

## Constraints

- Do not modify test files
- The function signature of `send_notification` must remain: `send_notification(channel, recipient, message, **kwargs)`
- Return values must be identical dicts for every case
