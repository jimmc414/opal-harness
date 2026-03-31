# OPAL: Next Steps Plan

## The question we're actually answering

Everything in this project serves one question: **Does giving an LLM agent a structured workspace with a deterministic completion gate produce better outcomes than letting it work freeform?**

"Better" means: higher completion rate on tasks that require recovery from failure, without degrading performance on tasks that don't. That's it. If the answer is no, the project produced a well-designed negative result. If the answer is yes, the follow-up question is: which parts of the harness are responsible, and at what cost?

---

## Phase 1: Manual Validation (5 tasks)

**Goal:** Determine whether the harness is *behaviorally real* — does the agent actually follow the protocol, and does following it change what happens?

### Task selection

| Task | Type | Tier | Why this one |
|------|------|------|-------------|
| bugfix-01-whitespace-strip | Bugfix | 1 | Simplest possible. If the harness hurts here, overhead is too high. |
| bugfix-08-regex-backtrack | Bugfix | 2 | Has `dead-ends` tag. Tests whether the agent abandons a failed approach or loops. |
| bugfix-10-float-precision | Bugfix | 2 | Has `mid-check` tag. Tests whether the agent runs informal intermediate checks. |
| bugfix-09-timezone-dst | Bugfix | 2 | Has `donesh-bug` tag. Tests whether done.sh will be subtly wrong and whether the agent handles it. |
| refactor-07-split-module | Refactor | 3 | Genuinely hard, multi-file, needs re-planning. Tests the full ORIENT→PLAN→ACT→CHECK→REPAIR loop. |

### How to run

**Bare condition (run first for each task):**
1. Fresh Claude Code session. No conversation history.
2. Provide the task.md content as the prompt. Copy repo/ into a working directory.
3. Give Claude Code the same tool access it would have under OPAL (terminal, file read/write/edit).
4. Let it work until it declares itself done or stalls. No time limit for manual runs — observe the natural stopping behavior.
5. Run eval.sh against the final state. Record pass/fail.
6. Save the full transcript.

**OPAL condition (run second for each task):**
1. Fresh Claude Code session. No conversation history.
2. Initialize the .opal/ workspace per the spec's initialization protocol.
3. Copy repo/ into work/.
4. Populate .opal/task.md from the task's task.md.
5. Copy harness.md into .opal/harness.md.
6. CLAUDE.md contains the reference line.
7. Prompt: "Read .opal/harness.md and begin work on the task described in .opal/task.md."
8. Let it work until it reaches DONE, STUCK, or PAUSE.
9. Run eval.sh against the final state of work/. Record pass/fail.
10. Archive the entire .opal/ directory.
11. Save the full transcript.

### What to observe (not just pass/fail)

For the OPAL runs, after each task, inspect the .opal/ directory:

**Protocol adherence:**
- Did the agent actually write state.md at phase transitions?
- Does state.md have the correct fields (Phase, Cycle, Summary, Next Action, Blocking Issues, Artifacts, Check Command)?
- Did it write done.sh with acceptance criteria as comments?
- Did it update plan.md when its understanding changed?
- Did log.md get real entries or boilerplate?
- Did Dead Ends get populated on tasks that triggered failed approaches?

**Behavioral differences:**
- Did the bare agent and OPAL agent take different approaches to the same task?
- Did the OPAL agent catch something via done.sh that the bare agent missed?
- Did the OPAL agent waste cycles on harness overhead that didn't help?
- On the donesh-bug task (bugfix-09): did the agent follow the modification protocol or silently rewrite the check?

**Stopping behavior:**
- Did the bare agent stop at the right time? Too early? Keep polishing?
- Did the OPAL agent's done.sh actually gate completion correctly?

### Decision criteria after Phase 1

| Observation | Interpretation | Action |
|------------|---------------|--------|
| Agent ignores harness.md, doesn't write state.md or done.sh | Protocol is not naturally followable | Restructure harness.md before proceeding. Do not automate a broken protocol. |
| Agent follows protocol but outcomes are identical to bare | Harness is overhead without value | Investigate whether specific modules (done.sh, Dead Ends) have any independent effect before abandoning. |
| Agent follows protocol, Tier 1 task takes 3x longer | Overhead too high for simple tasks | Consider a "light mode" that skips planning/state for simple tasks, or accept the trade-off and document it. |
| Agent follows protocol, Tier 2/3 tasks improve | Harness works as designed | Proceed to Phase 2. |
| Agent follows protocol, done.sh is consistently trivial (exit 0) | Completion gate is a fiction | The central design claim fails. Requires fundamental rethinking of how the check is authored. |
| Mixed results — helps on some tasks, hurts on others | Expected outcome | Analyze which task characteristics predict harness value. Proceed to Phase 2 with refined hypotheses. |

**If Phase 1 shows the agent doesn't follow the protocol, stop here.** Do not build automated infrastructure for a protocol that agents ignore. Go back to harness.md and figure out why. This is the most important decision gate in the entire project.

---

## Phase 2: Automated Runner (50 tasks)

**Goal:** Statistically meaningful comparison across the full task suite.

**Prerequisite:** Phase 1 showed the agent follows the protocol and there's at least directional evidence of behavioral difference.

### Build the runner

The runner needs to:

1. **Initialize a fresh environment per task.** Docker container or equivalent. No state leakage.
2. **Set up the bare condition:** copy repo/ to working directory, provide task.md as prompt, invoke Claude Code CLI with appropriate flags.
3. **Set up the OPAL condition:** same as bare plus .opal/ workspace initialization, harness.md, CLAUDE.md reference line.
4. **Capture outputs:** transcript, final working directory state, .opal/ directory (OPAL condition only).
5. **Run eval.sh** against the final state. Record exit code.
6. **Handle timeouts.** Hard timeout per task — calibrate from Phase 1 observations. Use 2x the longest Phase 1 OPAL run as the starting timeout.

### Run protocol

Based on Phase 1 learnings and budget:

**If budget allows (recommended):**
- 3 runs per task per condition = 300 total runs
- Report mean completion rate with standard deviation per tier
- This gives confidence intervals

**If budget constrained:**
- 1 run per task per condition = 100 total runs
- Acknowledge results are directional
- Focus analysis on paired task-level comparisons rather than aggregate rates

### Record keeping

For every run, archive:
- Pass/fail (eval.sh exit code)
- Transcript
- Final working directory state
- .opal/ directory (OPAL condition)
- Wall-clock time
- Token usage (if available from CLI)
- Cycle count (OPAL condition, from state.md)
- Final phase (OPAL condition: DONE/STUCK/PAUSE)

---

## Phase 3: Analysis

**Goal:** Answer the core question and the follow-up questions.

### Primary analysis

**Completion rate by tier:**

| | Bare | OPAL | Δ |
|---|---|---|---|
| Tier 1 (20 tasks) | ? | ? | Must be ≥ -5% or overhead is too high |
| Tier 2 (20 tasks) | ? | ? | This is where value should appear |
| Tier 3 (10 tasks) | ? | ? | Small sample, directional only |
| Overall (50 tasks) | ? | ? | Headline number, but tier breakdown matters more |

**If Tier 1 Δ is worse than -5%:** the harness hurts easy tasks more than it helps hard ones. This is a negative result. Document it and investigate whether a lighter protocol could preserve Tier 2 gains without Tier 1 degradation.

**If Tier 2 Δ is positive and Tier 1 Δ is neutral:** the harness works as designed. The follow-up question is: how much of the gain comes from which module?

### Secondary analysis

**Recovery rate:** Of tasks where the first attempt failed (in either condition), what fraction recovered to eventual success? This is the harness's claimed value proposition — it should make recovery more likely.

**False completion rate:** How often did the agent declare DONE (bare: "I'm done"; OPAL: done.sh passed) when eval.sh says the task isn't actually solved? OPAL's false completion rate should be lower. If it isn't, done.sh isn't working.

**Loop rate:** How often did the agent retry a failed approach? Check OPAL's log.md and Dead Ends against bare transcripts. OPAL should have lower loop rate.

**done.sh audit:** For every OPAL DONE outcome:
- Does every acceptance criterion from task.md appear as a comment in done.sh?
- Does each comment have a corresponding check that actually tests the criterion?
- Does done.sh agree with eval.sh (strictness alignment)?

**Cost analysis:** What's the token overhead of the harness? Compute tokens-per-successful-completion for both conditions. If OPAL uses 3x more tokens for 10% more completions, is that worth it? This is a judgment call that depends on the use case, but the data should be reported.

### Mechanism-level analysis

For each mechanism tag, compare outcomes on tasks that carry that tag:

| Mechanism | Tasks | Bare completion | OPAL completion | Signal |
|-----------|-------|----------------|-----------------|--------|
| repair | 16 | ? | ? | Does bounded repair help? |
| dead-ends | 7 | ? | ? | Does Dead Ends tracking prevent loops? |
| replan | 6 | ? | ? | Does explicit re-planning help? |
| donesh-bug | 2 | ? | ? | Does the modification protocol work? |
| ... | | | | |

Small sample sizes per mechanism mean this is exploratory, not conclusive. But it tells you where to look if aggregate results are mixed.

---

## Phase 4: Iterate or Publish

### If results are positive (Tier 2 improves, Tier 1 holds)

1. **Write up results.** Completion rates, tier breakdown, mechanism analysis, cost analysis, failure case studies. Publish to the repo and write a blog post or short paper.
2. **Identify which modules matter.** If the data suggests done.sh is responsible for most of the gain, the rest of the harness might be unnecessary weight. If Dead Ends tracking is the key, maybe that's the only thing worth keeping.
3. **Test on a different agent.** The harness claims to be agent-agnostic. Run the same 50 tasks with a different agent (Codex CLI, aider, a custom agent) to see if the results replicate. Cross-agent replication is the strongest evidence.
4. **Consider real-world tasks.** The current suite is 100% synthetic. Run against real GitHub issues (e.g., a SWE-bench subset) to test generalization.

### If results are negative (no improvement, or Tier 1 degradation)

1. **Publish the negative result.** This is still valuable. "Structured workspaces don't help LLM agents on these task types" is a finding the community should know.
2. **Analyze why.** Look at the transcripts. Is the agent ignoring the harness? Is it following the harness but the harness's structure doesn't match the task's structure? Is done.sh quality the bottleneck?
3. **Consider whether the protocol is too heavy.** Maybe the full ORIENT→PLAN→ACT→CHECK loop is overkill and the only thing that helps is done.sh alone. Test the components in isolation: just done.sh, just state.md, just Dead Ends.
4. **Consider whether the tasks are wrong.** If the synthetic tasks are too clean or too well-specified, they might not exercise the failure modes the harness is designed to address. Real-world tasks are messier, and that mess might be where the harness provides value.

### If results are mixed (helps on some, hurts on others)

This is the most likely outcome. The analysis should focus on:
- **What task characteristics predict harness value?** Task length? Number of files? Ambiguity of acceptance criteria? Likelihood of wrong first attempt?
- **Can you predict in advance whether to use the harness?** If the answer is "use it for tasks longer than N steps" or "use it when acceptance criteria are ambiguous," that's a useful result even if the overall completion rate delta is small.

---

## Final Desired State

The project is done when it has:

1. **A tested harness spec** with empirical evidence of where it helps and where it doesn't.
2. **Published results** (positive, negative, or mixed) with enough detail for others to replicate.
3. **A working test runner** that anyone can use to re-run the evaluation or run it against a different agent.
4. **An honest README** that reports what was found, not what was hoped for.

The goal is not to prove OPAL works. The goal is to find out whether it works, document the answer with evidence, and make the evidence available. If the harness is useful, people will adopt it. If it isn't, the test suite and methodology are still contributions — they can be used to evaluate other harness designs.

The project succeeds if someone reading the repo can answer: "Should I use this for my agent?" and the answer is grounded in data, not claims.
