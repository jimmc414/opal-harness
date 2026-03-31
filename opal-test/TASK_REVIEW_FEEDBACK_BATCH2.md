# Task Review Feedback — Batch 2 (bugfix 13-15 + feature 01-08)

Apply these fixes before proceeding to Batch 3. After each source-file edit, re-run eval.sh against the broken/unmodified repo to confirm it still fails as expected.

---

## Critical: eval.sh must test all stated acceptance criteria

### Feature 04 (rate-limit) — 2 untested criteria

**Criterion 3 (per-IP independence):** All eval tests use the same IP (`127.0.0.1`). A global counter passes everything. Add a test that sends requests with different `REMOTE_ADDR` values and verifies independent counters.

**Criterion 4 (time window expiry):** No time-based test exists. Either add a test that mocks `time.time()` to simulate window expiry, or remove criterion 4 from acceptance criteria if it's not worth testing. Don't state requirements you don't verify.

### Feature 08 (retry-backoff) — backoff timing untested

"Backoff delays double with each retry attempt" (task.md line 14) is the core feature but eval.sh only checks attempt counts. Add a test that patches `time.sleep` and asserts the call arguments double (e.g., `[call(1), call(2)]` or similar).

### Feature 07 (audit-log) — ISO 8601 not validated

eval.sh Test 6 (line 120) checks `timestamp is not None` but acceptance criterion requires "ISO 8601 format." Add `datetime.fromisoformat(entry['timestamp'])` assertion — this is one line.

---

## Moderate: Tier miscalibration

### Bugfix 15 (config-precedence) — demote to Tier 2

This is a single-file fix in a 27-line file with no dead-ends and no multi-file complexity. The task.md names the exact two failing env vars (`APP_PORT`, `APP_DEBUG`), making diagnosis trivial. Current mechanism tags ("pause", "checkpoint") are passive, not difficulty-creating.

Options:
1. **Demote to Tier 2 with "repair" mechanism** (simplest, acknowledges reality)
2. **Rework to be genuinely Tier 3**: add a second subtle bug, make the loading across multiple files, remove the specific var names from task.md. This is more work but would give the suite a 3rd real Tier 3 bugfix task.

### Bugfix 13 (cascade-orphan) — borderline, consider hardening

The existing `assignments_by_department` query helper makes the correct cascade fix too discoverable. If an agent reads `queries.py`, the path is obvious. Consider removing or obfuscating the cascade-specific helpers so the agent has to construct the deletion logic from the schema.

---

## Moderate: Missing edge case

### Feature 03 (healthcheck) — needs an "easy to miss" criterion

Currently trivially solvable with `return jsonify({"status": "healthy"})`. No criterion trips up a naive implementation. Add at least one of:
- `POST /health` must return 405 (Method Not Allowed)
- Response body must contain exactly `{"status": "healthy"}` with no extra keys
- The health endpoint must not affect item data

---

## Minor: eval.sh gaps

### Feature 05 (cursor-pagination) — base64 not validated

eval.sh imports `base64` (line 47) but never uses it. The "base64-encoded cursor" acceptance criterion is untested. Either add a `base64.b64decode(cursor)` assertion, or remove the base64 requirement from task.md.

### Feature 06 (webhook) — Test 6 mock asymmetry

Test 4 correctly patches both `urllib.request.urlopen` and `requests.post`. Test 6 (deleted webhook not triggered, lines 124-151) only patches `urllib`. If the agent uses `requests` for dispatch, Test 6 passes vacuously. Add the dual-mock pattern to Test 6 to match Test 4.

---

## Minor: Consistent formatting

### All 11 tasks — `## Problem` heading

All task.md files use either `## Description` or unlabeled text instead of the spec-required `## Problem` heading. The content is functionally present but the heading is wrong. Restructure to match the template: `## Source`, `## Problem`, `## Acceptance Criteria`, `## Constraints`.

---

## Next Steps

Once fixes are applied and eval.sh re-verified, proceed to Batch 3 (feature-09, feature-10, refactor-01 through refactor-08). Apply the same standards:
- No hint comments in source
- No `__pycache__`
- eval.sh must test every stated acceptance criterion
- task.md uses correct section headings
- At least one "easy to miss" criterion per task
- Tier rating matches actual difficulty
