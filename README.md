# OPAL: Orient-Plan-Act-Loop

A minimal agent harness designed from the LLM's perspective.

## What this is

OPAL is a structured workspace and operating protocol for LLM coding agents. It gives the agent a state file to read on every cycle, a mutable plan, an append-only log, and a deterministic completion gate (a bash script that exits 0 or 1). The agent can't declare itself done until the check passes.

The core loop is simple: Orient (read state, assess situation) → Plan (if needed) → Act (one logical change) → Check (run the completion gate) → Repair or Done.

## Why this exists

LLM agents have a few failure modes that are hard to fix with better prompting:

- **They don't know when to stop.** Without a machine-checkable completion gate, agents declare success based on vibes. OPAL requires a `done.sh` script that must exit 0 before the agent can stop.
- **They forget what they tried.** After context truncation, agents re-attempt failed approaches because there's no persistent record. OPAL maintains a `Dead Ends` section in the plan file that survives truncation.
- **They lose track of where they are.** Long tasks drift. OPAL requires a `state.md` file (max 30 lines) that the agent overwrites at every phase transition and checkpoints every 3 action cycles.
- **They over-explore.** Given latitude, agents generate alternative approaches speculatively. OPAL says: try your best approach, check if it works, re-plan only on failure.

## Results

### Phase 1: Synthetic Tasks (5 tasks x 2 conditions)

All 5 tasks were direct-solve difficulty. Both conditions achieved 100% pass rate.

| Metric | Bare | OPAL |
|--------|------|------|
| Pass rate | 5/5 | 5/5 |
| Total cost | $1.79 | $2.50 |
| Avg turns | 12.4 | 26.2 |
| OPAL adherence | — | 95% avg |

**Finding:** Tasks too easy. Opus solved everything on the first try. OPAL added 40% cost overhead with no pass-rate improvement.

### Phase 2: SWE-bench Real Bugs (5 sympy tasks x 2 conditions)

Real GitHub issues from the SWE-bench Lite dataset, tested against the sympy codebase (~650K lines).

| Metric | Bare | OPAL |
|--------|------|------|
| Pass rate | 5/5 | 4/5* |
| Total cost | $1.95 | $2.72 |
| Avg turns | 11.0 | 21.0 |
| OPAL adherence | — | 100% (on completed runs) |

*One OPAL run failed due to rate limits (0 turns, $0 cost), not methodology.

**Finding:** Same story — Opus solves these bugs directly. OPAL's value isn't in single-bug fixing. Need harder tasks with partial-success scoring.

### What We Learned

1. **Agents do follow the protocol.** OPAL artifact adherence averaged 95-100%. The harness is behaviorally real, not noise.
2. **The overhead is consistent.** ~2x turns, ~40% more cost across both phases.
3. **Bug-fixing is the wrong test.** Opus solves bugs on the first try. OPAL is designed for tasks that require recovery, replanning, and state tracking — we haven't tested those yet.
4. **Phase 3 needs different task types.** Large refactors, greenfield implementations, or multi-step integration tasks with graded (not binary) evaluation.

## Project structure

```
├── INTENT.md                           ← Design philosophy
├── spec/
│   ├── OPAL_HARNESS_SPEC_v0.2.0.md    ← Design document
│   ├── harness.md                      ← Operating protocol (agent reads this)
│   └── OPAL_TEST_SUITE_REQUIREMENTS.md ← Evaluation framework
├── docs/
│   ├── NEXT_STEPS.md                   ← Phased execution plan
│   ├── PHASE3_IDEAS.md                 ← Future test designs (graded eval)
│   ├── project_state.md                ← Current state snapshot
│   └── command_reference.md            ← AI-focused usage guide
└── opal-test/
    ├── tasks/                          ← Test tasks
    │   ├── bugfix/    (15)             ← Synthetic bug fixes
    │   ├── feature/   (10)
    │   ├── refactor/   (8)
    │   ├── config/     (7)
    │   ├── document/   (5)
    │   ├── data/       (5)
    │   └── swebench/   (5)            ← Real SWE-bench instances
    ├── runner/                         ← phase1.sh, phase2.sh, run_task.sh
    ├── results/                        ← Transcripts, metrics, artifacts
    ├── swebench/                       ← Instance selection tooling
    └── analysis/                       ← compare.py
```

## The workspace

When OPAL is active, the agent works in a structured workspace:

```
.opal/
├── harness.md     ← Operating protocol (read once at start)
├── state.md       ← Current state (read FIRST every cycle, max 30 lines)
├── task.md        ← Problem statement (immutable)
├── plan.md        ← Working plan (mutable — updated as understanding changes)
├── log.md         ← Action log (append-only)
└── checks/
    └── done.sh    ← Completion gate (must exit 0 to finish)
work/              ← The actual project files
```

`state.md` is the load-bearing file. If context gets truncated, the agent reads it and knows: what phase it's in, what's done, what's next, and what the completion check is. Everything else is reference material.

## The completion gate

`done.sh` is the most opinionated design choice. The agent writes it during planning. It must include every acceptance criterion from the task as a comment, with a corresponding check below each one:

```bash
#!/bin/bash
set -e

# Acceptance: All existing tests pass
pytest tests/ -x -q

# Acceptance: New test covers the reported case
pytest tests/test_reported_case.py -x -q
```

This has an obvious circularity: the same LLM judgment the harness is designed to distrust is writing the trust mechanism. The comment requirement makes gaps visible, but it doesn't eliminate the problem.

## How this was made

The spec was developed through an adversarial review process between two Claude instances (claude.ai and Claude Code) operating in different contexts. Same model weights, different system prompts, genuine disagreements resolved toward the stronger argument across three review rounds.

The test tasks were built by a separate Claude Code instance deliberately given no knowledge of the harness design — only the test suite requirements document.

## Current status

- [x] Spec finalized (v0.2.0)
- [x] Operating protocol written (harness.md)
- [x] 50 synthetic test tasks + 5 SWE-bench tasks
- [x] Runner scripts (phase1.sh, phase2.sh, run_task.sh)
- [x] Phase 1: synthetic tasks (5/5 bare, 5/5 OPAL)
- [x] Phase 2: SWE-bench real bugs (5/5 bare, 4/5 OPAL)
- [ ] Phase 3: harder tasks with graded evaluation
- [ ] Cross-agent testing (non-Claude agents)
- [ ] Results published

## Contributing

If you want to run the test suite against a different agent (not Claude Code), that would be the most valuable contribution — the harness should be agent-agnostic, and cross-agent results would test that claim.

If you find a structural problem with the spec, open an issue. If you find a bug in a test task's `eval.sh`, that's especially valuable — eval.sh correctness is the ground truth for the entire evaluation.

## License

MIT
