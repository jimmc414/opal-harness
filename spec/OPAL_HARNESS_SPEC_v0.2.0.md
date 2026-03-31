# OPAL: Orient-Plan-Act-Loop Harness Specification

**Version:** 0.2.0  
**Purpose:** A minimal general-purpose agent harness optimized for how LLMs actually process context, recover from failure, and determine completion.

---

## Design Principles

1. **State-first context.** The agent reads current state before instructions. Where-am-I precedes how-to.
2. **Single agent, flat workspace.** No role-switching, no multi-agent orchestration by default. One coherent perspective throughout.
3. **Deterministic completion.** Success is defined by a runnable check, not the agent's judgment.
4. **Small atomic steps.** One logical change per ACT phase, regardless of how many files it touches.
5. **Mutable plans.** The plan updates as understanding deepens. Initial plans are hypotheses, not contracts.
6. **Bounded recovery.** Retry limits are explicit. Looping is the default failure mode of LLM agents; the harness must prevent it.

---

## Workspace Structure

```
project/
├── CLAUDE.md              ← Project-specific instructions (user-owned)
├── .opal/
│   ├── harness.md         ← Harness logic (agent operating protocol)
│   ├── state.md           ← Current state (read FIRST on every cycle)
│   ├── task.md            ← Original problem statement (immutable after init)
│   ├── plan.md            ← Working plan (mutable)
│   ├── log.md             ← Append-only action log
│   └── checks/
│       └── done.sh        ← Machine-checkable completion gate
└── work/                  ← Actual working directory (code, files, artifacts)
```

### CLAUDE.md Reference Convention

CLAUDE.md belongs to the project and the user. The harness does not own it. CLAUDE.md should contain one reference line:

```markdown
Read .opal/harness.md for agent operating protocol before beginning work.
```

This keeps harness logic out of the user's project instructions and eliminates contention for CLAUDE.md space.

### Context Loading Order

**On initial task start:**
1. `.opal/harness.md` — How should I operate?
2. `.opal/state.md` — Where am I? (will say ORIENT, cycle 1)
3. `.opal/task.md` — What am I doing?

**On every subsequent cycle or resume:**
1. `.opal/state.md` — Where am I?
2. `.opal/task.md` — What am I doing?
3. `.opal/plan.md` — How am I doing it?
4. `.opal/log.md` (tail, last 3-5 entries) — What happened recently?

The agent internalizes harness.md once at startup. It does not re-read harness.md on every cycle. State.md is the file that changes every cycle and is always read first on resume, because "where am I" determines which part of the operating protocol is relevant.

---

## File Specifications

### `.opal/state.md`

The most important file in the system. Short. Max 30 lines. Updated at every phase transition.

```markdown
# State

## Phase
ORIENT | PLAN | ACT | CHECK | REPAIR | DONE | STUCK | PAUSE

## Cycle
3 of max 15

## Summary
2-3 sentences: what has been accomplished, what is the current focus.

## Next Action
One sentence: the specific next thing to do.

## Blocking Issues
None | description of what's blocking progress
(In PAUSE: the specific question needing human input and the options the agent sees.)

## Artifacts
Files or resources created during this task:
- work/src/validators/string.py (modified)
- work/tests/test_whitespace.py (created)

## Check Command
`pytest tests/ -x -q` or `bash .opal/checks/done.sh`
```

**Rules:**
- Overwrite on every update (not append).
- If context is truncated or the agent is resumed, reading this file alone must be sufficient to continue work.
- The Phase field drives the control flow.
- The Artifacts section tracks files created or modified, providing a cleanup manifest if the task reaches STUCK.

### `.opal/task.md`

The original problem statement. Written once at initialization. Never modified.

```markdown
# Task

## Source
GitHub issue #1234 | user request | ticket description

## Problem
The original problem statement, copied verbatim or lightly formatted.

## Acceptance Criteria
What "done" looks like, expressed as checkable conditions:
- [ ] All existing tests pass
- [ ] New test covers the reported case
- [ ] No unrelated files modified

## Constraints
- Time/budget limits if any
- Files or directories that should not be touched
- Dependencies that should not be added
```

**Rules:**
- If the task source doesn't include explicit acceptance criteria, the agent writes its best-effort criteria during PLAN and flags them as inferred.
- Constraints are hard limits. Acceptance criteria can be refined during PLAN.

### `.opal/plan.md`

The working plan. Mutable. Updated whenever the agent's understanding changes.

```markdown
# Plan

## Approach
1-3 sentences describing the overall strategy.

## Steps
1. [x] Reproduce the issue
2. [x] Identify root cause
3. [ ] Apply fix to src/validators/string.py
4. [ ] Write regression test
5. [ ] Run full test suite

## Revised Understanding
Things learned during execution that changed the approach.
(Initially empty. Append as discoveries happen.)

## Dead Ends
Approaches tried and abandoned, with reasons.
(Prevents re-exploring failed paths after context truncation.)
```

**Rules:**
- Steps use `[x]` / `[ ]` checkboxes. The agent marks steps complete as they finish.
- When the agent discovers its initial approach is wrong, it rewrites the Steps section and logs the reason in Revised Understanding.
- Dead Ends is critical for long tasks — it survives context truncation and prevents loops.

### `.opal/log.md`

Append-only execution record. Each entry is one action and its outcome.

```markdown
# Log

## Cycle 1 — ORIENT
- Read task. Issue reports whitespace handling bug in string validator.
- Formed initial hypothesis: strip() applied asymmetrically.

## Cycle 2 — ACT
- Action: Ran `python -c "from validators import check; check(' hello ')"`
- Result: ValidationError raised. Bug confirmed.
- Duration: <1 min

## Cycle 3 — ACT
- Action: Read src/validators/string.py lines 130-160
- Result: Line 142 strips input but line 145 compares against raw expected value.
- Root cause identified.

## Cycle 4 — ACT
- Action: Modified line 145 to also strip expected value.
- Result: File saved.

## Cycle 5 — CHECK
- Command: `pytest tests/test_string_validator.py -x -q`
- Result: PASS (14 passed)
- Action: Moving to full test suite.
```

**Rules:**
- Never rewrite history. Append only.
- Each entry records: what was done, what happened, how long it took.
- Failed attempts stay in the log permanently. They're evidence, not noise.

### `.opal/checks/done.sh`

The completion gate. A runnable script that exits 0 on success, non-zero on failure.

**done.sh MUST include the acceptance criteria from task.md as comments at the top of the script.** This forces the agent to explicitly map each criterion to a check, and gives a human reviewer a single-glance comparison between what was asked and what is tested.

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

**Rules:**
- Written during PLAN. May be refined during execution if acceptance criteria sharpen.
- Must be deterministic. No LLM judgment calls inside the check.
- The agent cannot skip this gate. "It looks right to me" is not completion.
- Every acceptance criterion in task.md must appear as a comment in done.sh with a corresponding check below it. Gaps between criteria and checks must be visible.
- If the agent suspects done.sh itself has a bug, it must log the specific discrepancy in log.md and flag it in state.md Blocking Issues before modifying the check. Never silently fix the check.

---

## Phase Logic

### ORIENT
**Trigger:** Start of task, after any CHECK failure, after any unexpected ACT failure, or on resume from context loss.

**Actions:**
1. Read state.md, task.md, plan.md, recent log entries.
2. Assess: Do I understand the problem? Do I have a plan? Is the plan still valid?
3. Update state.md with current phase and understanding.
4. Transition to PLAN if no plan exists, or ACT if plan exists and next step is clear.

### PLAN
**Trigger:** First cycle, or when ORIENT determines the current plan is invalid.

**Actions:**
1. Analyze the task. Explore the work directory enough to understand the problem.
2. Write or rewrite plan.md with concrete steps.
3. Write or update .opal/checks/done.sh with the completion gate, including acceptance criteria as comments.
4. Update state.md. Transition to ACT.

**Rules:**
- Planning should take 1-2 cycles, not 10. Bias toward starting work.
- If acceptance criteria in task.md are vague, write the best-effort check and note it as inferred in plan.md.

### ACT
**Trigger:** Plan exists and next step is clear.

**Actions:**
1. Execute ONE logical change from the plan. A logical change may touch multiple files if they form a single coherent modification (e.g., renaming a function across call sites, adding an import and its usage).
2. Log the action and its result in log.md.
3. Mark the step complete in plan.md.
4. Update state.md.
5. If this was the last step in the plan, transition to CHECK. Otherwise, continue ACT for the next step.

**Informal mid-plan checks:** The agent MAY run the check command (or subsets of it, such as running a specific test file) during ACT to validate intermediate progress and catch compounding errors early. These informal checks do not trigger state transitions — they are diagnostic only. If an informal check reveals a problem, the agent handles it within ACT or transitions to ORIENT if the problem is fundamental.

**Rules:**
- One logical change per ACT cycle. The unit is coherence, not file count.
- If an ACT step reveals the plan is wrong, transition to ORIENT (not PLAN directly).
- If an ACT step fails in an unexpected way, log it and transition to ORIENT.

### CHECK
**Trigger:** All plan steps are marked complete.

**Actions:**
1. Run `.opal/checks/done.sh`.
2. Log the result.
3. If exit 0: update state.md phase to DONE. Stop.
4. If exit non-zero: update state.md phase to REPAIR. Include the failure output.

**Rules:**
- Do not interpret a failing check optimistically. If it fails, it fails.
- Do not modify the check script to make it pass unless the check itself had a bug. If you believe the check is wrong, log the specific discrepancy in log.md and flag it in state.md Blocking Issues before making any change to done.sh.

### REPAIR
**Trigger:** CHECK failed.

**Actions:**
1. Read the check failure output.
2. Diagnose: Is this a minor fix or does it invalidate the approach?
3. If minor: apply the fix (one ACT cycle), then re-CHECK.
4. If fundamental: transition to ORIENT to re-plan.
5. Increment the cycle counter.

**Rules:**
- Max 3 REPAIR cycles before transitioning to STUCK.
- Each repair attempt must be different from the previous one. (Check log.md and Dead Ends to avoid repeating failed approaches.)

### DONE
**Terminal state.** The check passed.

**Actions:**
1. Write final state.md with phase DONE and a summary of what was accomplished.
2. Final log entry with total cycles and outcome.
3. Stop. Do not continue working.

### STUCK
**Terminal state.** Retry limit reached or unrecoverable error.

**Actions:**
1. Write final state.md with phase STUCK and a clear explanation of:
   - What was attempted
   - Why it failed
   - What a human should look at
   - What artifacts were created (from the Artifacts section) that may need cleanup
2. Final log entry.
3. Stop. Do not attempt further work.

**Rules:**
- STUCK is an honest outcome, not a failure of the agent. Some tasks are genuinely beyond current capability or have ambiguous requirements.
- Never silently give up. Always explain what went wrong.

### PAUSE
**Terminal state (resumable).** The agent is blocked on external input.

**Trigger:** The agent encounters a decision that requires human judgment — ambiguous requirements, permission for a destructive action, a choice between approaches with materially different trade-offs that the task.md doesn't resolve.

**Actions:**
1. Update state.md:
   - Phase: PAUSE
   - Blocking Issues: The specific question needing an answer, and the options the agent sees.
   - Next Action: "Awaiting human input on: [one-line summary of the question]"
2. Log entry explaining what triggered the pause and why the agent cannot resolve it alone.
3. Stop. Do not attempt further work.

**Resumption:** The human edits state.md directly:
- Changes Phase from PAUSE to ORIENT
- Answers the question in Blocking Issues (or clears it and updates task.md with the clarification)

On resume, the agent reads state.md first (per the standard loading order), sees ORIENT, and continues.

**Rules:**
- PAUSE does NOT count against the cycle budget. The agent should not be penalized for asking a necessary question, and budget pressure should not incentivize guessing over asking.
- Max 1 PAUSE per task. An agent that needs to pause multiple times is dealing with an underspecified task that should be clarified upfront or rejected. If the agent reaches a second potential PAUSE, it should transition to STUCK instead and explain that the task needs more complete requirements.
- PAUSE is for genuine ambiguity, not for avoiding hard decisions. If the agent has enough information to make a reasonable choice, it should make the choice and log its reasoning rather than deferring to a human.

---

## Periodic State Checkpointing

**After every 3 ACT cycles, rewrite state.md from scratch** regardless of whether the phase changed. This is the agent's hedge against context truncation.

The rewrite should:
- Reflect the current state of the task, not the state from 3 cycles ago.
- Update the Summary with all progress since the last checkpoint.
- Update the Artifacts section with any new files created or modified.
- Update the Next Action to reflect what comes next.

This rule exists because the agent cannot reliably monitor its own context consumption. A fixed checkpoint interval is more valuable than a perfect adaptive rule the agent can't reliably apply.

---

## Global Rules

1. **Cycle budget.** Default max 15 cycles. Configurable per task in task.md. A cycle is one pass through any phase. ORIENT counts as a cycle. PAUSE does not.

2. **No role-switching.** You are one agent throughout. Do not adopt personas or pretend to be a "verifier" vs. a "solver." You are both.

3. **State-file discipline.** state.md is updated at EVERY phase transition. If you are interrupted between updates, the previous state must be sufficient to resume.

4. **Plan mutation.** When you learn something that changes your approach, update plan.md immediately. Do not continue following a plan you know is wrong.

5. **No speculative exploration.** Do not generate alternative approaches "just in case." Try your best approach. If it fails, ORIENT and re-plan with the new information.

6. **Log honesty.** Log failures and dead ends with the same detail as successes. Future-you (or a resumed context) depends on this.

---

## Adapting to Task Types

The harness is task-agnostic. Adaptation happens in two places:

### task.md — defines WHAT
Different task types produce different acceptance criteria and constraints.

| Task Type | Typical Check Command | Key Constraints |
|-----------|----------------------|-----------------|
| Bug fix | `pytest tests/ -x -q` | Don't break existing tests |
| Feature | `pytest && python -c "import feature; feature.demo()"` | Follow existing patterns |
| Document | `test -f output.pdf && python validate_pdf.py output.pdf` | Match format spec |
| Config | `systemctl is-active service && curl -s localhost/health` | Don't disrupt running services |
| Data | `python validate_schema.py output.csv && wc -l output.csv` | Preserve all records |
| Refactor | `pytest tests/ -x -q && diff <(git diff --stat) expected.txt` | Behavior-preserving |

### done.sh — defines WHEN
The completion gate is the primary adaptation mechanism. A well-written done.sh encodes the task type's success criteria without the harness needing to know about task taxonomies.

---

## Initialization Protocol

When a task arrives, the agent bootstraps the workspace:

```bash
# 1. Create workspace structure
mkdir -p .opal/checks work

# 2. Write harness.md (the operating protocol)
# Copy from template or reference location
cp /path/to/opal/harness-template.md .opal/harness.md

# 3. Add reference to CLAUDE.md (create if it doesn't exist, append if it does)
echo "Read .opal/harness.md for agent operating protocol before beginning work." >> CLAUDE.md

# 4. Write task.md from the incoming problem statement
cat > .opal/task.md << 'EOF'
# Task
[populated from incoming request]
EOF

# 5. Initialize state.md
cat > .opal/state.md << 'EOF'
# State
## Phase
ORIENT
## Cycle
1 of max 15
## Summary
Task received. Beginning orientation.
## Next Action
Read task.md and assess the problem.
## Blocking Issues
None
## Artifacts
None yet.
## Check Command
TBD (will be defined during PLAN)
EOF

# 6. Initialize empty plan and log
echo -e "# Plan\n\nNot yet created." > .opal/plan.md
echo "# Log" > .opal/log.md

# 7. done.sh placeholder
cat > .opal/checks/done.sh << 'EOF'
#!/bin/bash
echo "No completion check defined yet"
exit 1
EOF
chmod +x .opal/checks/done.sh
```

Then the agent begins the ORIENT phase.

---

## Testing the Harness

To evaluate whether this harness works, compare against a bare baseline on the same task set.

### Control Variables
- Same LLM, same temperature, same tool access
- Same task set, same evaluation criteria
- Only difference: presence or absence of .opal/ workspace + harness.md

### Metrics That Matter
1. **Completion rate.** Did the check pass?
2. **Cycle count.** How many cycles to completion? (Lower is better.)
3. **Recovery rate.** Of tasks that failed on first attempt, how many recovered?
4. **False completion rate.** How often did the agent declare DONE when the check actually failed? (Should be 0 by construction, but worth verifying.)
5. **Loop rate.** How often did the agent repeat a failed approach? (Check log.md for duplicates.)

### Metrics That Don't Matter
- Token count (unless comparing cost-effectiveness at equal completion rates)
- Number of tool calls (a proxy for nothing useful)
- "Quality" judgments by another LLM

### done.sh Audit
**For every DONE outcome in the test set, manually inspect done.sh.** Verify:
- Every acceptance criterion from task.md appears as a comment in done.sh.
- Each comment has a corresponding check that actually tests the criterion (not a no-op or trivially passing command).
- The check tests the right thing — not a weaker proxy for the actual criterion.

This is the most important quality gate in the testing protocol. A harness that achieves high completion rates by writing permissive checks is worse than no harness at all.

### Suggested Test Protocol
1. Select 50+ tasks spanning at least 3 task types from the adaptation table. Tasks should deliberately include cases that stress failure-recovery paths (mid-course re-planning, REPAIR cap, context truncation recovery, ambiguous requirements triggering PAUSE), not just straightforward happy-path work. The harness's primary value is in failure recovery — a test suite that doesn't exercise failure modes can't measure that value.
2. Run all tasks bare (no harness). Record outcomes.
3. Run the same tasks with OPAL harness. Record outcomes.
4. Compare completion rate, cycle efficiency, and recovery rate.
5. Audit done.sh for every DONE outcome (see done.sh Audit above).
6. Manually inspect 10 STUCK outcomes — are the explanations useful? Do they identify the right problem?
7. Manually inspect all PAUSE outcomes — were the questions reasonable? Would a human answer have unblocked the task?
8. Check for loop rate in log.md — did Dead Ends tracking prevent repeated failed approaches?

The most informative comparison will be tasks where the harness reaches STUCK with a clear explanation vs. tasks where the bare agent silently produces wrong output. The harness should lose fewer tasks to silent failure, even if it doesn't solve more tasks overall.

---

## Appendix: Multi-Agent Extension

For tasks that genuinely benefit from parallelism (not most tasks), the harness supports a minimal delegation model. This extension is not part of the core v0.2.0 spec and should not be implemented until the single-agent model has been validated through testing.

```markdown
## In plan.md:
### Parallel Steps
- [ ] Step 3a: Run test suite A → child agent, shares .opal/ read-only
- [ ] Step 3b: Run test suite B → child agent, shares .opal/ read-only

### Delegation Rules
- Child agents get: task.md (read-only), their specific step, work/ (read-write to subdirectory)
- Child agents write results to: work/results/{step_id}.md
- Parent waits for all children, reads result files, updates log.md and plan.md
```

**Rules:**
- Default is single-agent. Only use delegation for genuinely independent work.
- Children do not get their own .opal/ directories. They are workers, not autonomous agents.
- The parent is always responsible for CHECK and DONE decisions.
