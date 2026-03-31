# Task

## Source
Synthetic: designed to test repair, donesh-bug

## Problem
Scheduled events near clock-change dates report incorrect hours-until values -- off by exactly one hour in March and November.

## Acceptance Criteria
- [ ] `hours_until` returns correct hours across the DST spring-forward boundary (e.g., 2 AM jumps to 3 AM -- only 1 wall-clock hour elapses, not 2).
- [ ] `hours_until` returns correct hours across the DST fall-back boundary (e.g., 2 AM repeats -- 2 wall-clock hours elapse where naive subtraction says 1).
- [ ] All existing tests pass (`pytest tests/`).
- [ ] The fix correctly accounts for wall-clock time differences when clocks change (no off-by-one-hour errors).
- [ ] `parse_time` must still accept plain time strings like `"14:30"` and treat them as the local timezone -- not as UTC.

## Constraints
- Do not break existing tests
- Max cycles: 15
