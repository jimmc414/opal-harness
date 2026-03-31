# Task Review Feedback — Batch 3 (feature 09-10 + refactor 01-08)

Batch quality is noticeably improved from Batches 1-2. No hint comments, no cache dirs, proper task.md headings throughout. The remaining issues are all eval.sh coverage gaps — stated criteria without corresponding tests.

After each fix, re-run eval.sh against the unmodified repo to confirm it still fails as expected.

---

## eval.sh must test all stated acceptance criteria

### Feature 09 (RBAC) — viewer-cannot-PUT untested

task.md line 16 says viewer "cannot create, update, or delete items." eval.sh tests viewer-cannot-POST (test 6) and viewer-cannot-DELETE (test 7), but has **no test for viewer-cannot-PUT**. An agent allowing viewers to PUT passes all tests.

Fix: Add a test sending PUT to `/items/<id>` with a viewer token, asserting 403 + `{"error": "forbidden"}` body.

While you're at it: test 7 (viewer-cannot-DELETE, ~line 119) checks 403 status but does not verify the response body `{"error": "forbidden"}`, unlike tests 6 and 10. Add the body check for consistency.

### Feature 10 (db-migrations) — two gaps

1. **Timestamp untested.** task.md line 17 says the `_migrations` table tracks "a timestamp of when each was applied." No eval test checks for a timestamp column. Add an assertion that queries the `_migrations` table schema or reads the applied migration's timestamp value.

2. **Module path implicit.** task.md says "a migration runner module" without specifying `db/migrate.py`, but eval.sh hardcodes `from db.migrate import apply_migrations, rollback_migration`. An agent following only task.md might place it at `migrations/runner.py` and fail. Add the module path to acceptance criteria or constraints: "The migration runner must be importable as `from db.migrate import apply_migrations, rollback_migration`."

### Refactor 06 (sync-to-async) — Content-Type untested

task.md line 18: "post method must set Content-Type: application/json header." Neither eval.sh nor the existing test suite checks this. An agent could drop the header and pass.

Fix: Add an eval check that inspects the `post` method's request construction for the Content-Type header, or add a test that captures the outgoing request headers.

Also: HTTP error handling for `post` and `delete` (task.md line 17) is only tested for `get` (via existing `test_get_404`). Consider adding coverage for `post` and `delete` error paths.

### Refactor 07 (split-module) — math import constraint untested

task.md line 25: "The `math` import should only appear in modules that use it." `import math` in engine.py line 1 is completely unused — `math` is never referenced. After splitting, it should appear in zero modules.

Fix: Add `grep -rq 'import math' gamelib/ && echo "FAIL: math imported in a module that doesn't use it" && exit 1` or similar.

---

## Minor (nice to have)

### Refactor 06 — potential undeclared dependency

task.md allows the agent to use `aiohttp` or `httpx`, but if they do, eval.sh has no pip install step. Consider adding a note in constraints that the solution should work with stdlib only, or add a `pip install` guard.

---

## No changes needed

The following tasks are clean:
- Refactor 01 (extract-config) — thorough dual-verification
- Refactor 02 (rename-module) — good coverage including leftover-reference scan
- Refactor 03 (dead-code) — excellent cascading import trap
- Refactor 04 (strategy-pattern) — AST-based structural check is well-designed
- Refactor 05 (raw-to-orm) — good search_tasks dead-end potential
- Refactor 08 (dependency-injection) — strongest Tier 3 task in the suite

---

## Next Steps

Once fixes are applied and eval.sh re-verified, proceed to Batch 4 (config 01-07 + document 01-03). Apply the same standard: every stated acceptance criterion must have a corresponding eval.sh test.
