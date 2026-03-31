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

## What this is not

This is a research project, not a product. The spec has been through multiple review rounds but **zero tasks have been run against it yet**. The hypothesis is that this harness improves agent outcomes on multi-step coding tasks, particularly tasks that require recovery from failed first attempts. That hypothesis is untested.

We don't know:
- Whether agents actually follow the protocol or just ignore it
- Whether the overhead hurts performance on easy tasks
- Whether `done.sh` quality is good enough to be a reliable gate
- Whether any of this matters once you account for the cost of the extra tokens

## Project structure

```
├── INTENT.md                           ← Design philosophy (why from the LLM's perspective)
├── spec/
│   ├── OPAL_HARNESS_SPEC_v0.2.0.md    ← Design document (the why)
│   ├── harness.md                      ← Operating protocol (the what — agent reads this)
│   └── OPAL_TEST_SUITE_REQUIREMENTS.md ← Evaluation framework
├── docs/
│   ├── NEXT_STEPS.md                   ← Phased execution plan
│   ├── project_state.md                ← Current state snapshot
│   └── TASK_WRITER_PROMPT.md           ← Prompt used to generate test tasks
└── opal-test/
    ├── tasks/                          ← 50 test tasks across 6 types and 3 tiers
    │   ├── bugfix/    (15)
    │   ├── feature/   (10)
    │   ├── refactor/   (8)
    │   ├── config/     (7)
    │   ├── document/   (5)
    │   └── data/       (5)
    ├── runner/                         ← Test runner scripts (stubs)
    ├── results/                        ← Where test results go
    └── analysis/                       ← Comparison and audit tools (stubs)
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

# Acceptance: No unrelated files modified
test $(git diff --name-only | grep -v "^tests/" | wc -l) -eq 0
```

This has an obvious circularity: the same LLM judgment the harness is designed to distrust is writing the trust mechanism. The comment requirement makes gaps visible (a human can glance at the top of `done.sh` and see whether the criteria map to checks), but it doesn't eliminate the problem. The test suite includes `donesh-bug` tasks specifically designed to probe this weakness.

## How this was made

The spec was developed through an adversarial review process between two Claude instances (claude.ai and Claude Code) operating in different contexts. Same model weights, different system prompts, genuine disagreements resolved toward the stronger argument across three review rounds.

The test tasks were built by a separate Claude Code instance that was deliberately given no knowledge of the harness design — only the test suite requirements document. This prevents the tasks from being reverse-engineered to fit the harness's phase transitions.

We're aware of the irony of using LLMs to design and review a framework for governing LLMs. The resulting spec should be evaluated on its merits, not its provenance.

## Current status

- [x] Spec finalized (v0.2.0)
- [x] Operating protocol written
- [x] Test suite requirements defined
- [x] 50 test tasks constructed and reviewed
- [ ] Manual validation runs (next — 5 tasks, bare vs. harnessed)
- [ ] Runner scripts implemented
- [ ] Analysis tooling implemented
- [ ] Full 50-task comparison
- [ ] Results published

## What would change our mind

If manual runs show that agents ignore the protocol and produce the same outcomes with or without harness.md, the approach needs fundamental rethinking — not parameter tuning.

If `done.sh` quality is consistently poor (agents write trivial checks that always pass), the deterministic completion gate is a fiction and the design's central claim collapses.

If Tier 1 tasks (simple, direct-solve) show >5% worse completion rates with the harness than without, the overhead isn't justified regardless of Tier 2/3 gains.

## Contributing

This is early-stage research. If you want to run the test suite against a different agent (not Claude Code), that would be the most valuable contribution — the harness should be agent-agnostic, and cross-agent results would test that claim.

If you find a structural problem with the spec, open an issue. If you find a bug in a test task's `eval.sh`, that's especially valuable — eval.sh correctness is the ground truth for the entire evaluation.

## License

MIT
