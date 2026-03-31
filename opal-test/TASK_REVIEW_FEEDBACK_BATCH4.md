# Task Review Feedback — Batch 4 (config 01-07 + document 01-03)

---

## Critical: eval.sh execution bugs

### Config 07 (multi-stage-docker) — `python` vs `python3`

eval.sh uses `python` (not `python3`) on lines 21, 33, 59, 70, 109. On Ubuntu/Debian without the `python-is-python3` package, `python` doesn't exist. Change all to `python3` for portability. All other tasks use `python3`.

### Config 04 (compose-network) — `set -e` + `$?` conflict

eval.sh uses `set -euo pipefail` but then checks `$?` after python3 blocks (lines 177, 231). Under `set -e`, a nonzero python3 exit aborts the script before reaching the `$?` check. Fix: use the `cmd && pass || fail` pattern from the other config tasks, or prefix python3 blocks with `|| true`.

Also: the YAML fallback in python blocks 2 and 3 (lines 153-158, 190-195) falls back to empty dicts instead of using the manual parser from block 1. This gives false positives when pyyaml is absent.

---

## eval.sh must test all stated criteria

### Config 04 — network attachment and dependency direction

1. **Network attachment untested.** AC2 says "all services are attached to [the custom network]." eval.sh only checks that a `networks:` top-level section exists. Add a check that each service block contains a `networks:` entry.

2. **Dependency direction untested.** eval.sh checks that `depends_on` exists somewhere but not which service depends on which. Add checks for the specific dependency chain.

### Config 07 — .dockerignore incomplete check

AC6 requires `.dockerignore` excludes `.git`, `__pycache__`, `tests/`, `*.pyc`, `.pytest_cache`. eval.sh only checks the first three. Add checks for `*.pyc` and `.pytest_cache`.

### Document 01 (api-docs) — response codes

task.md line 18: "documents response codes (at least 200/201 and 400/404 where applicable)." eval.sh only checks that a `responses` key exists. Add a check that at least one 2xx and one 4xx code appear per endpoint.

### Document 03 (adr) — Title section and Status validation

1. **"Title" section never checked.** task.md requires "Title, Status, Context, Decision, Consequences" but eval.sh only checks Status, Context, Decision, Consequences. Add "Title" to the loop.

2. **Status validation false-positive.** The check searches the entire file for valid status words ("proposed", "accepted", etc.), not just the Status section. An ADR with invalid Status but "proposed" mentioned in Context passes. Fix: check the line immediately following the Status header, not the whole file.

---

## Tier miscalibration

### Config 05 (ci-pipeline) — demote to Tier 1

The task is "fix 2 typos in a YAML file" (`pytst` → `pytest`). No multi-step reasoning, no dependencies, no repair scenario. Demote to Tier 1 / direct-solve.

### Config 07 (multi-stage-docker) — consider demoting to Tier 2

No genuine dead-end or replan scenario. Standard Docker best practices solve it in one pass. The "pause" and "checkpoint" mechanism tags are passive, not difficulty-creating. Either demote to Tier 2 or add genuine complexity (e.g., an app dependency requiring build-stage compilation artifacts).

---

## eval.sh bugs (non-blocking)

### Config 03 (json-logging) — ISO 8601 validation is a no-op

eval.sh line 148: `ts.rstrip('+00:00')` strips individual characters (`+`, `0`, `:`), not the substring. The fallback (line 154) accepts anything containing `T`. Net effect: any string with `T` passes the ISO 8601 check. Fix: use `datetime.fromisoformat()` instead.

### Config 06 (env-management) — ast.Str removed in Python 3.12

eval.sh line 104: `isinstance(node.value, (ast.Constant, ast.Str))`. `ast.Str` was removed in Python 3.12. Use `ast.Constant` only.

---

## Minor

- Config 04 task.md: missing `#` title heading (line 1 starts with `## Source`)
- Document 03 task.md: missing `#` title heading
- Config 07 eval.sh: `run_check` function suppresses all diagnostic output (`> /dev/null 2>&1`)
- Document 02: category checks ("Added"/"Fixed"/"Changed") are bare string matches — should check for markdown headers (`## Added`)
- Config 05: easy-to-miss criterion (step name) is very weak — the name is already correct in the repo

---

## No changes needed

- Config 01 (https-redirect) — clean
- Config 02 (cors) — excellent eval.sh using Flask test client
- Config 06 (env-management) — well-designed SECRET_KEY AST check

---

## Next Steps

Once fixes are applied and eval.sh re-verified, proceed to Batch 5 (document 04-05 + data 01-05). This is the final batch.
