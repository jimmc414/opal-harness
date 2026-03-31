# Final Review — OPAL Test Suite (50 tasks)

## Must fix before testing

### 1. Clean cache artifacts (ALL repos contaminated)

```bash
cd /mnt/c/python/temp_tasks/opal-test/tasks
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null
find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null
```

94 `__pycache__` dirs and 42 `.pytest_cache` dirs across all 50 repos.

### 2. `pause` mechanism needs 1 more task (have 2, need 3)

Current pause tasks: `document/05-migration-guide`, `feature/09-rbac`. Add `pause` to one more task's `expected_mechanisms` in metadata.json. Candidate: `bugfix/15-config-precedence` (already has ambiguous requirements that could trigger PAUSE).

### 3. Add missing acceptance criteria for tested behaviors

**data/05-schema-migrate**: eval test #12 checks `purchased_at → transaction_date` column mapping. Add to task.md Acceptance Criteria: "`purchased_at` column maps to `transaction_date` in the transactions table."

**document/05-migration-guide**: eval check #13 tests `count → total` field rename. Either add to task.md Acceptance Criteria, or remove the eval check.

## Should fix (not blocking)

### 4. document/05-migration-guide prescriptive docstrings

`api/v2.py` has docstrings that spell out every change:
- Line 9: "Renamed from /items to /products. Response format changed."
- Line 16: "Renamed item_id to product_id."
- Line 25: "Required fields changed: 'title' instead of 'name', 'cost' instead of 'price'."
- Line 35: "Changed from PUT to PATCH. Field names changed."

For a Tier 3 task, these make the work too easy. Consider replacing with neutral docstrings that describe what each endpoint does, not what changed.

## Verified clean

- 50/50 tasks: all required files present
- 50/50 metadata.json: valid JSON, all fields, correct types
- 50/50 task.md: correct section headings (Source, Problem, Acceptance Criteria, Constraints)
- 0 hint comments in production source code across all repos
- Type distribution: 15 bugfix, 10 feature, 8 refactor, 7 config, 5 document, 5 data
- Tier distribution: 21 Tier 1, 21 Tier 2, 8 Tier 3 (2 short of ~10 target, acceptable)
- Mechanism coverage: all 9 mechanisms meet minimums except pause (1 short)

## Ready for testing after fixes 1-3
