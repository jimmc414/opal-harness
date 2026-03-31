# Task Review Feedback — Bugfix Batch (Tasks 01-12)

Reviewed by Claude Code Opus. Apply these changes before proceeding to the next task batch.

---

## Critical (must fix before testing)

### 1. Remove all BUG/BUGGY/VULNERABLE comments from source code

Every task (except 01) has comments in the source files that explicitly label the bug and often describe the fix. These hand the agent the answer without requiring diagnostic work, which defeats the purpose of a bugfix test.

**What to remove:** All `# BUG:`, `# BUGGY:`, `# VULNERABLE`, `NOTE: This implementation is BUGGY`, and similar annotations from source files. The source code should look like normal production code with a subtle bug, not annotated teaching material.

Specific locations:

| Task | File | Lines |
|------|------|-------|
| 02 | `repo/paginator/core.py` | 33 |
| 03 | `repo/userapi/formatters.py` | 15-16 |
| 05 | `repo/fileprocessor/reader.py` | 17-18 |
| 06 | `repo/taskqueue/tasks.py` | 18, 45 |
| 07 | `repo/productservice/service.py` | 46, 58-60 |
| 08 | `repo/validators/email.py` | 6-8 |
| 09 | `repo/scheduler/events.py` | 3-5, 25-28 |
| 10 | `repo/billing/invoice.py` | 1, 25, 29 |
| 11 | `repo/fileserver/app.py` | 3-5, 22 |
| 12 | `repo/database/query.py` | 3-5, 22, 37 |

Also remove:
- Task 04: cycle-tracing comments like `# step 1 of cycle`, `# step 3 of cycle -- CIRCULAR!` (these trace the exact bug path)
- Task 12: `pool.py` line 2 comment "should NOT be modified to fix the bug" (over-directs the agent)

### 2. Clean `__pycache__/` and `.pytest_cache/` from all repos

All 12 tasks ship with Python bytecode caches. Remove them:
```bash
find tasks/ -type d -name __pycache__ -exec rm -rf {} +
find tasks/ -type d -name .pytest_cache -exec rm -rf {} +
```

### 3. After removing comments, re-verify eval.sh still works

**IMPORTANT:** Removing comments and BUG annotations changes line numbers in source files. After making edits to any source file:
1. Run `pytest tests/ -x -q` in each modified repo to confirm tests still fail on the bug as expected.
2. Run `eval.sh` against the unmodified (still-buggy) repo to confirm it correctly reports failure.
3. If any eval.sh has line-number-dependent assertions, update them.

This is a sanity check, not a full re-test — but skipping it risks shipping tasks where eval.sh passes on buggy code or fails on correct code because of shifted line numbers.

---

## Moderate (should fix)

### 4. Restructure task.md to match the required template

All 12 tasks use `Description`, `Files of Interest`, `Acceptance Criteria`, `Reproducing the Bug`. The required sections are `Source`, `Problem`, `Acceptance Criteria`, `Constraints` (as defined in OPAL_TEST_SUITE_REQUIREMENTS.md).

Map the existing content:
- `Description` → split into `Source` (synthetic, designed to test [mechanism]) and `Problem` (the symptom description)
- `Files of Interest` → fold into `Problem` or `Constraints`
- `Reproducing the Bug` → fold into `Problem`
- Add `Constraints` section (even if just "Do not break existing tests")

### 5. Reduce root-cause specificity in task.md

The `Problem` section should describe **symptoms**, not diagnoses. Let the agent find the root cause. Current worst offenders:

- Task 05: "using `encoding='utf-8-sig'`" (literally the fix)
- Task 09: "calls `datetime.now()` instead of using timezone-aware datetimes" (the exact root cause)
- Task 12: "do not use `try/finally`" (literally the fix technique)

Rewrite these to describe what the user observes (the bug behavior) without explaining why it happens.

### 6. Add `notes` field to metadata.json for tasks 01-07

Tasks 08-12 have the `notes` field. Tasks 01-07 do not. Add notes that describe expected agent behavior or failure modes.

### 7. Re-tier task 07 (cache-stale)

Currently rated Tier 2 / `repair`. The fix is a single line (`self._cache.invalidate(product_id)`) and the cache API already provides the method. Re-tier to Tier 1 / `direct-solve`.

---

## Minor (nice to have)

### 8. Task 08 (regex-backtrack): eval.sh uses `pytest --timeout=10`

This requires `pytest-timeout` which is not declared in any requirements file. Either add a `requirements.txt` with `pytest-timeout` or remove the `--timeout` flag and rely on the `signal.SIGALRM` timeout already in eval.sh.

### 9. Task 04 (import-cycle): consider bumping to Tier 2

Import cycles have multiple valid solutions (TYPE_CHECKING, lazy import, restructuring). This involves more architectural judgment than a typical Tier 1 direct-solve.

---

## What's Done Well (keep as-is)

- **eval.sh quality is excellent.** Independent, deterministic, idempotent, tests the right things. Particularly strong: task 03 (raw JSON validation), task 04 (inspect.signature), task 11 (encoded path traversal).
- **"Easy to miss" criteria are well-designed.** Task 03 (null vs ""), task 06 (defensive copy), task 11 (symlinks), task 12 (double-fault). These are genuine traps.
- **Bugs are realistic** — real patterns from real codebases.
- **Repos are self-contained** with test suites that correctly fail on the bug.

---

## Next Steps

Once all fixes above are applied and eval.sh re-verification passes (section 3), proceed to the next batch of tasks. The remaining task types needed per OPAL_TEST_SUITE_REQUIREMENTS.md are:

| Task Type | Target Count | Status |
|-----------|-------------|--------|
| Bug fix | 15 | 12 done (need ~3 more) |
| Feature | 10 | 0 done |
| Refactor | 8 | 0 done |
| Config | 7 | 0 done |
| Document | 5 | 0 done |
| Data | 5 | 0 done |

Apply the same quality standards from this review to all future batches: no BUG comments in source, no `__pycache__`, task.md describes symptoms not root causes, and use the correct template sections.
