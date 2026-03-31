# Task Review Feedback — Round 2 (Bugfix Batch Verification)

Most feedback from Round 1 was applied correctly. Five tasks have residual issues. Fix these before proceeding to Batch 2.

After each fix, re-run `pytest tests/ -x -q` in the affected repo to confirm tests still fail on the bug as expected (same sanity check as Round 1 section 3).

---

## Task 04 (import-cycle)

**File:** `repo/app/__init__.py` line 3
**Issue:** Comment `# This import triggers the circular dependency chain` names the root cause.
**Fix:** Replace with a neutral comment like `# Convenience re-exports` or remove entirely.

## Task 06 (mutable-default)

**File:** `repo/taskqueue/tasks.py` line 19
**Issue:** Comment `# Tags from previous calls leak into subsequent calls that don't` describes the exact bug mechanism in production source.
**Fix:** Remove the comment. The test docstrings mentioning "mutable default" are acceptable — tests naturally describe what they test.

## Task 09 (timezone-dst)

**File:** `task.md` — Acceptance Criteria, criterion about timezone handling
**Issue:** Criterion says "All times are handled as timezone-aware (using `datetime.timezone`, `zoneinfo`, or equivalent). No naive datetimes should be used in time arithmetic." This prescribes the fix technique and names specific modules.
**Fix:** Rephrase to describe the desired outcome without prescribing technique. Example: "Time calculations must produce correct results across DST transitions (e.g., spring-forward and fall-back boundaries)."

## Task 10 (float-precision)

**File:** `repo/billing/formatter.py` line 4
**Issue:** Comment says "After the precision fix the formatter must still produce exactly two decimal places" — telegraphs that precision is the root cause.
**Fix:** Rephrase to something neutral like "The formatter must produce exactly two decimal places for all dollar amounts."

## Task 12 (conn-leak) — most fixes needed

Four locations still contain answer-giving annotations:

| File | Line | Issue | Fix |
|------|------|-------|-----|
| `repo/database/connection.py` | 4 | "so that the connection-leak bug in query.py can be exercised" — names and locates the bug | Remove or rephrase to neutral docstring about the module's purpose |
| `repo/database/migrations.py` | 3 | "Uses execute_query internally, so it inherits the connection leak bug" — names and locates the bug | Remove or rephrase to describe what the module does, not what bug it has |
| `repo/tests/test_pool.py` | 1 | "these all pass (pool is not buggy)" — tells agent where NOT to look | Remove the parenthetical. Just describe what the tests cover. |
| `repo/tests/test_query.py` | 118 | "if the fix calls conn.close() in cleanup" — describes the fix technique | Remove or rephrase to describe the test's assertion without naming the fix |

---

## Next Steps

Once these 5 tasks are cleaned up and sanity-checked, proceed to Batch 2. Remaining task types needed:

| Task Type | Target Count | Status |
|-----------|-------------|--------|
| Bug fix | 15 | 12 done (need ~3 more) |
| Feature | 10 | 0 done |
| Refactor | 8 | 0 done |
| Config | 7 | 0 done |
| Document | 5 | 0 done |
| Data | 5 | 0 done |

Apply the same standard to all future tasks: source code should read like normal production code, not annotated teaching material. If a comment names the bug, locates it, or describes the fix technique, it needs to go.
