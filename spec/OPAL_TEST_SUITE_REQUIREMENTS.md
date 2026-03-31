# OPAL Harness Test Suite Requirements

**Version:** 0.2.0  
**Purpose:** Define the task suite for comparative evaluation of the OPAL harness against a bare baseline.

---

## Test Structure

```
opal-test/
├── tasks/                      ← Task definitions
│   ├── bugfix/
│   │   ├── 01-whitespace-strip/
│   │   │   ├── task.md         ← Problem statement + acceptance criteria
│   │   │   ├── repo/           ← Starting state of the codebase
│   │   │   └── eval.sh         ← Ground-truth evaluator (independent of done.sh)
│   │   ├── 02-off-by-one/
│   │   └── ...
│   ├── feature/
│   ├── config/
│   ├── document/
│   ├── data/
│   └── refactor/
├── runner/
│   ├── run_bare.sh             ← Execute task without harness
│   ├── run_opal.sh             ← Execute task with OPAL harness
│   └── evaluate.sh             ← Compare outcomes
├── results/
│   ├── bare/
│   └── opal/
└── analysis/
    ├── compare.py              ← Completion rate, cycle count, recovery rate
    └── audit_donesh.py         ← Automated pre-screen of done.sh quality
```

---

## Task Selection Criteria

### Quantity and Distribution

Minimum 50 tasks total. Distribution across task types:

| Task Type | Count | Rationale |
|-----------|-------|-----------|
| Bug fix | 15 | Core use case, clear acceptance criteria, testable |
| Feature | 10 | Tests plan mutation and multi-step coherence |
| Refactor | 8 | Tests behavior-preservation discipline |
| Config | 7 | Tests non-code completion gates |
| Document | 5 | Tests artifact creation and format validation |
| Data | 5 | Tests schema validation and data integrity |

### Difficulty Tiers

Each task type should span three difficulty tiers:

**Tier 1 — Direct solve (40% of tasks).** Single logical change, obvious root cause, straightforward check. These establish the baseline. If the harness hurts performance on Tier 1 tasks, the overhead is too high.

**Tier 2 — Multi-step with recovery (40% of tasks).** Requires 3-7 logical steps. At least one step should involve a likely wrong first attempt that requires diagnosis and repair. These are the tasks where the harness should show its value — Dead Ends tracking, state recovery, bounded repair.

**Tier 3 — Stress tests (20% of tasks).** Deliberately designed to exercise specific harness mechanisms:
- Tasks that require enough steps to trigger the periodic state checkpoint (>6 ACT cycles).
- Tasks with ambiguous requirements that should trigger PAUSE.
- Tasks where the obvious approach fails and re-planning is necessary (tests ORIENT → re-PLAN flow).
- Tasks where the correct solution touches many files (tests "one logical change, multiple files" rule).
- Tasks where an intermediate check would catch a compounding error that final CHECK alone would miss.

### Selection Principles

**Tasks must stress the harness's failure-recovery paths, not just its happy path.** A test suite of 50 trivial tasks that any agent solves in 2 cycles tells you nothing about whether Dead Ends tracking prevents loops, whether REPAIR caps prevent thrashing, or whether state checkpointing survives context truncation. At least 30 of the 50 tasks should be capable of triggering at least one failure-recovery mechanism.

**Tasks must have unambiguous ground-truth evaluation.** Every task needs an eval.sh that is independent of the agent's done.sh. This is the experiment's evaluator — it determines whether the task was actually solved, regardless of what the agent's own check says. The comparison between done.sh and eval.sh is itself a metric (done.sh fidelity).

**Tasks should be drawn from real-world sources when possible.** Synthetic tasks risk testing harness compliance rather than harness utility. Prefer tasks sourced from real GitHub issues, real configuration problems, real data-cleaning scenarios. Where synthetic tasks are necessary (e.g., to guarantee PAUSE triggers), document them as synthetic.

---

## Task Definition Format

Each task is a directory containing:

### `task.md` (Required)

The problem statement the agent receives. Must include:

```markdown
# Task

## Source
Real: github.com/org/repo/issues/123
Synthetic: designed to test [mechanism]

## Problem
[Clear problem statement]

## Acceptance Criteria
- [ ] [Criterion 1 — must be machine-checkable]
- [ ] [Criterion 2]
- [ ] [Criterion N]

## Constraints
- Max cycles: 15 (or task-specific override)
- [Any file/dependency/scope constraints]
```

**Rules for acceptance criteria:**
- Every criterion must be expressible as a bash command that exits 0/1. If a criterion can't be machine-checked (e.g., "code should be readable"), either make it concrete ("code passes pylint with no errors") or drop it. The harness depends on deterministic checks — vague criteria undermine the entire architecture.
- Include at least one criterion that is easy to miss. This tests whether the agent's done.sh maps all criteria, not just the obvious ones.

### `repo/` (Required)

The starting state of the work directory. Copied into `work/` at task start. For bug-fix tasks, this is the codebase with the bug present. For document tasks, this might be empty or contain templates. For config tasks, this contains the system state that needs modification.

**Rules:**
- Must be self-contained. No external dependencies that might change between runs.
- Include a README or equivalent that gives the agent enough context to understand the codebase/environment.
- For bug-fix and refactor tasks, include an existing test suite that the agent must keep passing.

### `eval.sh` (Required)

The ground-truth evaluator. Independent of the agent's done.sh. This is what the experiment uses to determine whether the task was actually solved.

```bash
#!/bin/bash
set -e

# Ground-truth evaluation — independent of agent's done.sh
# This script is NEVER shown to the agent.

cd "$WORK_DIR"

# Check 1: The specific bug is fixed
python -c "
from validators import check
result = check(' hello ')
assert result == True, f'Expected True, got {result}'
"

# Check 2: Existing tests still pass
pytest tests/ -x -q

# Check 3: Only the expected files were modified
CHANGED=$(git diff --name-only)
echo "$CHANGED" | grep -q "src/validators/string.py" || exit 1
UNEXPECTED=$(echo "$CHANGED" | grep -v "^src/validators/string.py$" | grep -v "^tests/" | wc -l)
test "$UNEXPECTED" -eq 0
```

**Rules:**
- eval.sh must be stricter than or equal to a reasonable done.sh. It should catch cases where the agent's check passes but the task isn't actually solved.
- eval.sh is never shown to the agent. It is the experimenter's tool, not the agent's.
- eval.sh must be deterministic and idempotent. Running it twice produces the same result.

### `metadata.json` (Required)

```json
{
  "id": "bugfix-01-whitespace-strip",
  "type": "bugfix",
  "tier": 2,
  "source": "real",
  "source_url": "https://github.com/org/repo/issues/123",
  "expected_mechanisms": ["repair", "dead-ends"],
  "estimated_cycles": 5,
  "notes": "First attempt will likely strip both sides; correct fix is input-only strip."
}
```

The `expected_mechanisms` field documents which harness mechanisms the task is designed to exercise. This is for analysis, not for the agent — it helps the experimenter verify that the test suite has coverage across mechanisms.

Valid mechanism tags:
- `direct-solve` — Tier 1, should complete without recovery
- `repair` — Expected to trigger at least one REPAIR cycle
- `dead-ends` — Expected to trigger a failed approach that must be abandoned
- `replan` — Expected to require ORIENT → re-PLAN after initial plan fails
- `checkpoint` — Long enough to trigger periodic state checkpoint
- `pause` — Contains genuine ambiguity that should trigger PAUSE
- `multi-file` — Correct solution touches 3+ files as one logical change
- `mid-check` — Intermediate checking would catch a compounding error
- `donesh-bug` — The agent's done.sh will be subtly wrong (tests wrong path, too-strict comparison, etc.); tests whether the agent follows the modification protocol (log discrepancy → flag in Blocking Issues → then modify) rather than silently rewriting the check

---

## Evaluation Framework

### Primary Metrics

Computed automatically by `compare.py`:

| Metric | Definition | Computed From |
|--------|-----------|---------------|
| **Completion rate** | % of tasks where eval.sh exits 0 | eval.sh results |
| **Cycle efficiency** | Mean cycles to DONE for completed tasks | state.md final cycle count |
| **Recovery rate** | % of tasks that reached REPAIR and still completed | log.md phase history |
| **False completion rate** | % where agent declared DONE but eval.sh fails | done.sh vs eval.sh |
| **Loop rate** | % of tasks where the same approach was tried twice | log.md + Dead Ends |
| **STUCK quality** | % of STUCK outcomes with actionable explanation | Manual review |

### done.sh Audit Metrics

Computed by `audit_donesh.py` and manual review:

| Metric | Definition |
|--------|-----------|
| **Criteria coverage** | % of task.md acceptance criteria that appear as comments in done.sh |
| **Check validity** | % of done.sh checks that actually test what their comment claims |
| **Strictness alignment** | % of tasks where done.sh and eval.sh agree on pass/fail |

### Mechanism Coverage

Computed from metadata.json across the task suite:

| Mechanism | Min Tasks Required |
|-----------|-------------------|
| direct-solve | 15 |
| repair | 10 |
| dead-ends | 5 |
| replan | 5 |
| checkpoint | 5 |
| pause | 3 |
| multi-file | 5 |
| mid-check | 3 |
| donesh-bug | 2 |

Each mechanism must be exercised by at least the minimum number of tasks. If the suite falls short on any mechanism, add targeted tasks before running the experiment.

---

## Execution Protocol

### Bare Baseline

For each task:
1. Copy `repo/` into a clean working directory.
2. Provide the agent with `task.md` content as the prompt.
3. Give the agent the same tool access (terminal, file read/write/edit) as the OPAL condition.
4. No harness files, no .opal/ directory, no operating protocol.
5. Let the agent work until it declares completion, with a hard timeout as a safety cap (2x the wall-clock time of the longest OPAL run in a calibration set, or a generous fixed limit such as 30 minutes). Do not impose an artificial cycle-equivalent budget — let the bare agent work naturally so that outcome differences are attributable to the harness, not resource starvation.
6. Run eval.sh against the final state of the working directory.
7. Record: pass/fail, token usage, time, number of tool calls.

### OPAL Condition

For each task:
1. Copy `repo/` into `work/`.
2. Initialize the .opal/ workspace per the initialization protocol in the spec.
3. Populate `.opal/task.md` from the task's `task.md`.
4. Copy `harness.md` into `.opal/harness.md`.
5. Ensure CLAUDE.md contains the harness reference line.
6. Let the agent work under the OPAL protocol until DONE, STUCK, or PAUSE.
7. Run eval.sh against the final state of `work/`.
8. Record: pass/fail, cycle count, final phase, all .opal/ files for analysis.
9. Archive the full .opal/ directory for post-hoc review.

### Environment Controls

- Same LLM model and version for both conditions.
- Same temperature (0 recommended for reproducibility).
- Same tool access and permissions.
- Same compute environment.
- Fresh container/environment per task (no state leakage between tasks).
- Fixed random seed where the LLM API supports it.
- **Run count:** 3 runs per task per condition if budget allows (300 total runs). Report mean completion rate with standard deviation. If budget constrains to single runs, acknowledge in the report that results are directional, not statistically significant. The protocol should specify this upfront rather than leaving it to the test runner's judgment.

---

## What Success Looks Like

The harness is worth using if the OPAL condition shows:

1. **Equal or higher completion rate** on Tier 1 tasks (the harness must not add overhead that hurts easy tasks).
2. **Meaningfully higher completion rate** on Tier 2 tasks (the harness should help most on tasks requiring recovery).
3. **Lower false completion rate** (done.sh should catch errors that bare agents miss silently).
4. **Lower loop rate** (Dead Ends tracking should prevent repeated failed approaches).
5. **Useful STUCK explanations** (when the harness fails, the failure should be informative).

The harness is NOT worth using if:
- It hurts Tier 1 completion rate by more than 5% (overhead too high).
- False completion rate is above 10% (done.sh is being written too permissively).
- Cycle efficiency on Tier 1 tasks is 2x+ worse than bare (the protocol is slowing down easy work).

These thresholds are starting points. Adjust based on the first round of results.
