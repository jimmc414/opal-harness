# OPAL Project State

**Date:** 2026-03-30
**Repo:** https://github.com/jimmc414/opal-harness
**Status:** Spec complete, test suite complete, zero tasks run

---

## What exists

### Specification (finalized)

**OPAL_HARNESS_SPEC_v0.2.0.md** — The design document. Defines the ORIENT → PLAN → ACT → CHECK → REPAIR/DONE/STUCK/PAUSE loop, workspace structure, file formats, phase logic, and global rules. Developed through 3 rounds of adversarial review between two Claude Opus 4.6 instances (claude.ai with extended thinking and Claude Code with max reasoning). The "creative tension" process produced genuine disagreements that resolved toward the stronger argument each time.

Key design decisions that survived all review rounds unchanged (the "load-bearing walls"):
- State-first context loading (state.md read before anything else on every cycle)
- Deterministic completion gates (done.sh must exit 0; agent can't self-declare DONE)
- Dead Ends tracking in plan.md (prevents retry loops after context truncation)
- Append-only log (failed attempts are evidence, not noise)
- Immutable task / mutable plan separation
- Single-agent-first philosophy
- Bounded recovery (max 3 REPAIR cycles, max 15 total cycles, PAUSE doesn't count)

Changes from v0.1.0 to v0.2.0:
1. "One logical change" replaces file-count heuristic for ACT atomicity
2. Harness logic moved from CLAUDE.md to `.opal/harness.md` (eliminates contention)
3. Periodic state checkpoint every 3 ACT cycles (hedge against context truncation)
4. Informal mid-plan checks permitted during ACT (diagnostic only, no state transitions)
5. PAUSE added as a distinct terminal state (blocked on human input ≠ STUCK)
6. Cycle budget bumped from 10 to 15
7. Artifacts section added to state.md
8. done.sh must include acceptance criteria as comments mapping to checks

### Operating Protocol (finalized)

**harness.md** — 168 lines. The agent reads this once at task start. Organized phase-first (the agent's most common question is "I'm in phase X, what do I do?"). Includes file format reminders (added after review identified that agents after context truncation know to update state.md but not what fields it contains).

### Test Suite Requirements (finalized)

**OPAL_TEST_SUITE_REQUIREMENTS.md** — Defines task structure, evaluation framework, execution protocol, and success criteria. Key design decisions:
- eval.sh is independent of the agent's done.sh (the experiment's ground truth)
- Bare baseline lets the agent run until it declares done (with hard timeout), not an artificial cycle budget
- 3 runs per task per condition if budget allows (300 total); single run with caveat if not
- Success = equal/higher completion on Tier 1, meaningfully higher on Tier 2, lower false completion, useful STUCK explanations

### Test Suite (50 tasks, reviewed)

**opal-test/tasks/** — 50 tasks across 6 types and 3 tiers:

| Type | Count | Purpose |
|------|-------|---------|
| bugfix | 15 | Core use case, clearest eval criteria |
| feature | 10 | Tests plan mutation, multi-step coherence |
| refactor | 8 | Tests behavior-preservation discipline |
| config | 7 | Tests non-code completion gates |
| document | 5 | Tests artifact creation, format validation |
| data | 5 | Tests schema validation, data integrity |

**Tier distribution:** 21 Tier 1 / 21 Tier 2 / 8 Tier 3

**Mechanism coverage (all minimums met):**

| Mechanism | Count | Min |
|-----------|-------|-----|
| direct-solve | 21 | 15 |
| repair | 21 | 10 |
| dead-ends | 8 | 5 |
| replan | 7 | 5 |
| checkpoint | 5 | 5 |
| multi-file | 9 | 5 |
| mid-check | 4 | 3 |
| donesh-bug | 2 | 2 |
| pause | 3 | 3 |

Each task has: task.md (problem statement), metadata.json (tier/mechanisms/notes), eval.sh (ground-truth evaluator), repo/ (starting codebase).

**Review process:** 5 batches, each reviewed by parallel agents checking for hint comments in source code, eval.sh coverage of all stated criteria, tier calibration, cache artifacts, and task.md structure. Multiple rounds of fixes applied. Final verification confirmed: 0 hint comments in production source, all metadata valid, all task.md sections present, all cache dirs clean.

**Task writer prompt preserved** in TASK_WRITER_PROMPT.md for reproducibility.

### Infrastructure (stubs only)

**opal-test/runner/** — `run_bare.sh`, `run_opal.sh`, `evaluate.sh` exist but are not wired up. They need to:
- Start a fresh agent session
- Provide task prompt (bare) or initialize .opal/ workspace (OPAL)
- Let agent run to completion or terminal state
- Run eval.sh against final work directory state
- Record results

**opal-test/analysis/** — `compare.py` and `audit_donesh.py` exist but are stubs. Need to compute the metrics defined in the spec (completion rate, cycle count, recovery rate, false completion rate, loop rate, done.sh fidelity).

---

## What doesn't exist

### No tasks have been run

Zero. The hypothesis that this harness improves agent outcomes is completely untested. The spec, harness, and test suite are all theory until an agent attempts a task.

### No runner implementation

The biggest engineering gap. The runner needs to:
1. Copy repo/ into a clean working directory
2. For OPAL: initialize .opal/ per the initialization protocol, copy harness.md, create CLAUDE.md reference line
3. Invoke the agent (Claude Code CLI? Agent SDK? API?) with the task
4. For bare: give the agent just the task.md content, no harness
5. Detect completion (DONE/STUCK/PAUSE for OPAL; agent declares done for bare)
6. Run eval.sh against final state
7. Archive all .opal/ files for post-hoc analysis
8. Handle timeouts, crashes, and edge cases

The invocation method hasn't been decided. Options:
- **Claude Code CLI** (`claude --task "..."`) — most direct, but automation API unclear
- **Claude Agent SDK** — programmatic control, Max OAuth auth available
- **Direct API** — most control, but need to implement tool use (file read/write/edit, bash)

### No analysis tooling

compare.py and audit_donesh.py need to:
- Parse .opal/ state files to extract cycle counts, phase history
- Parse eval.sh results (pass/fail)
- Compare bare vs OPAL outcomes per task
- Compute aggregate metrics with confidence intervals (if multi-run)
- Audit done.sh for every DONE outcome (criteria coverage, check validity, strictness alignment)

### document/02-changelog git history

The changelog task requires git history to generate a changelog from. The embedded .git directory was removed during repo creation. The runner will need to reinitialize the git history from a setup script, or the task needs a git-bundle/tarball alternative.

---

## Known risks and open questions

### Will agents actually follow the protocol?

The harness.md is instructions, not enforcement. An agent could read it and ignore it entirely. The OPAL condition's value depends on the agent internalizing and following the phase logic, state-file discipline, and completion gate. If agents treat harness.md as background noise, the entire approach fails.

### Is done.sh quality good enough?

The spec's central claim is that deterministic completion gates are better than LLM judgment. But the LLM writes the gate. The comment-mapping requirement makes gaps visible, and the test suite includes donesh-bug tasks to probe this, but we don't know yet whether agents write meaningful checks or trivial ones.

### Does the overhead hurt Tier 1 tasks?

ORIENT + PLAN + state file updates + done.sh creation is overhead that a simple 2-cycle task doesn't need. If Tier 1 completion rates drop >5% with the harness, the overhead isn't justified regardless of Tier 2/3 gains.

### Token cost

The harness consumes tokens on state file reads/writes, plan updates, and log entries. At equal completion rates, is the harnessed version significantly more expensive? The spec says token count doesn't matter unless comparing cost-effectiveness at equal completion rates, but in practice cost matters.

### Context window pressure

harness.md is ~170 lines consumed on first read. State/plan/log reads add more on every cycle. For long tasks, this competes with the actual work context. The periodic checkpoint rule is designed to mitigate this, but it's untested.

---

## Process notes

### How the spec was developed

1. Jim provided the initial v0.1.0 spec to Claude Code Opus for review
2. Claude Code provided feedback (10 points). Claude.ai Opus reviewed the feedback, accepted 7, pushed back on 3 with reasoning.
3. Claude Code conceded where the author's argument was stronger, pushed back where warranted
4. 5 agreed changes were identified. Claude Code flagged 2 additional specification gaps (PAUSE state undefined, harness.md loading convention unspecified)
5. Author accepted both gaps, produced v0.2.0 incorporating all changes
6. Claude Code identified the done.sh comment requirement — the single most impactful suggestion in the exchange

### How the test suite was built

1. Claude Code wrote requirements for harness.md content and task suite composition
2. Author agreed and produced both documents
3. A separate clean Claude Code instance (no knowledge of harness design) built the tasks from the test suite requirements only
4. Claude Code reviewed each batch (5 batches), producing specific feedback
5. Clean instance applied fixes, Claude Code verified
6. Final structural verification confirmed all 50 tasks pass all checks

### What the "creative tension" process revealed

Same model weights in different contexts produced genuine disagreements:
- ORIENT counting against cycle budget (author right, Claude Code wrong)
- Error taxonomy (author right to cut it — existing flow handles implicitly)
- Plan-mutation trigger specificity (author right — overspecifying a judgment call adds false rigor)
- done.sh comment requirement (Claude Code right — structural prevention > detection)
- PAUSE as distinct from STUCK (Claude Code right — different semantics)

The most useful signal: elements that survived 3 rounds of adversarial review without either side touching them. Those are the core architecture.
