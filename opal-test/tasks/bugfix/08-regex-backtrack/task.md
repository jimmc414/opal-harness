# Task

## Source
Synthetic: designed to test repair, dead-ends

## Problem
The email validation endpoint hangs indefinitely on certain input strings. For example, submitting a 30-character local part followed by `@` with no valid domain causes the process to become unresponsive for minutes or longer.

## Acceptance Criteria
- [ ] Valid emails still validate correctly (standard addresses pass).
- [ ] Invalid emails are still rejected correctly (malformed addresses fail).
- [ ] `validate_email("a" * 30 + "@")` completes in under 2 seconds.
- [ ] All existing tests pass (`pytest tests/ -v` exits 0).
- [ ] The fix must still reject emails with consecutive dots in the domain (e.g., `user@foo..bar.com`).

## Constraints
- Do not break existing tests
- Max cycles: 15
