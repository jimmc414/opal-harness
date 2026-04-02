# OPAL Command Reference (for AI Agents)

This document explains how to use the OPAL test harness. It is written for
LLM-based coding agents that need to run experiments, create tasks, or
understand the project structure.

## Quick Start

### Run Phase 1 (synthetic tasks, ~$5, ~10 min)

```bash
cd "/path/to/Orient-Plan-Act-Loop Agent Harness Specification"
conda activate llm  # or your Python env with pytest
bash opal-test/runner/phase1.sh
```

Runs 5 synthetic tasks x 2 conditions (bare, OPAL) = 10 Claude invocations.
Interactive pauses between runs. Results in `opal-test/results/`.

### Run Phase 2 (SWE-bench tasks, ~$10-20, ~30 min)

```bash
bash opal-test/runner/phase2.sh
```

Runs 5 real sympy bugs from SWE-bench Lite. Same bare-vs-OPAL structure.
First run clones the sympy repo (~2 min); subsequent runs use cache.

### Run a single task

```bash
bash opal-test/runner/run_task.sh bugfix/01-whitespace-strip bare
bash opal-test/runner/run_task.sh bugfix/01-whitespace-strip opal
bash opal-test/runner/run_task.sh swebench/01-sympy-18621 bare
```

### View results

```bash
python3 opal-test/analysis/compare.py opal-test
```

## Project Layout

```
spec/
  harness.md                  # The OPAL protocol (agent reads this)
  OPAL_HARNESS_SPEC_v0.2.0.md # Design rationale document
  OPAL_TEST_SUITE_REQUIREMENTS.md

opal-test/
  tasks/                      # All test tasks
    bugfix/01-whitespace-strip/
      task.md                 # Problem description
      metadata.json           # Type, tier, mechanisms
      eval.sh                 # Ground-truth evaluation
      repo/                   # Buggy codebase
    swebench/01-sympy-18621/
      task.md                 # From GitHub issue
      metadata.json
      eval.sh                 # Applies test_patch, runs pytest
      setup_repo.sh           # Clones repo at base_commit
      test_patch.diff         # New tests (not shown to agent)
      swebench_instance.json  # Full SWE-bench data

  runner/
    phase1.sh                 # Orchestrator for synthetic tasks
    phase2.sh                 # Orchestrator for SWE-bench tasks
    run_task.sh               # Run a single task
    setup_workspace.sh        # Initialize bare or OPAL workspace
    check_artifacts.sh        # Verify OPAL artifact quality

  results/
    bare/<task-id>/
      transcript.jsonl        # Full Claude conversation
      result                  # "PASS" or "FAIL"
      metrics.json            # Timing, cost, exit codes
      workspace/              # Agent's working directory
    opal/<task-id>/
      transcript.jsonl
      result
      metrics.json
      workspace/
      opal_archive/           # Copy of .opal/ after run
      artifact_check.json     # Adherence score

  swebench/
    select_instances.py       # Filter SWE-bench for candidates
    create_task.py            # Generate OPAL task from instance

  analysis/
    compare.py                # Compute metrics across conditions
```

## How Tasks Work

### Synthetic Tasks (bugfix/, feature/, refactor/, etc.)

Each task has a `repo/` directory with buggy code, a `task.md` with the
problem description, and an `eval.sh` that validates the fix independently
of what the agent thinks it did.

**Bare condition:** Agent receives task.md content as a prompt. Works
directly in a copy of repo/. No harness files.

**OPAL condition:** Agent starts in a workspace with CLAUDE.md pointing to
`.opal/harness.md`. Repo is in `work/`. Agent follows the OPAL protocol:
reads state.md, creates plan.md, writes done.sh, works in cycles.

### SWE-bench Tasks (swebench/)

Same structure but `repo/` is replaced by `setup_repo.sh` that clones
a real open-source project at a specific commit. Eval applies a test patch
(hidden from the agent) and runs the SWE-bench FAIL_TO_PASS tests.

## Creating New Tasks

### Synthetic task

```bash
mkdir -p opal-test/tasks/bugfix/16-my-task/repo
# Add buggy code to repo/
# Write task.md, metadata.json, eval.sh
```

**task.md format:**
```markdown
# Task

## Source
Synthetic: designed to test <mechanism>

## Problem
<description>

## Acceptance Criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

## Constraints
- Do not break existing tests
- Max cycles: 15
```

**metadata.json format:**
```json
{
  "id": "bugfix-16-my-task",
  "type": "bugfix",
  "tier": 2,
  "source": "synthetic",
  "expected_mechanisms": ["dead-ends", "repair"],
  "estimated_cycles": 5,
  "notes": "Description of what this tests"
}
```

**eval.sh requirements:**
- Uses `$WORK_DIR` (set by runner)
- Exits 0 = PASS, non-zero = FAIL
- Tests each acceptance criterion independently
- Ends with `echo "ALL CRITERIA PASSED"`

### SWE-bench task

```bash
python3 opal-test/swebench/select_instances.py  # Find candidates
python3 opal-test/swebench/create_task.py <instance_id> <number>
```

This generates the full task directory from a SWE-bench instance ID.

## Runner Architecture

### setup_workspace.sh

```
setup_workspace.sh <task_dir> <bare|opal> <output_dir>
```

- **bare:** Copies `repo/` (or runs `setup_repo.sh`) into output_dir
- **opal:** Creates `.opal/` with harness.md, state.md, plan.md, log.md,
  done.sh placeholder. Copies repo into `work/`. Creates CLAUDE.md.

### run_task.sh

```
run_task.sh <task_id> <bare|opal>
```

1. Calls setup_workspace.sh
2. Invokes Claude Code CLI with `--dangerously-skip-permissions`
3. Archives .opal/ (OPAL condition)
4. Runs eval.sh
5. Writes result, metrics.json

**Budgets:**
- Synthetic: $5 bare / $15 OPAL
- SWE-bench: $15 bare / $30 OPAL

### phase1.sh / phase2.sh

Orchestrators that loop over tasks, run bare then OPAL, check artifacts,
and print a summary table. Use `read -p` for interactive pauses (requires
a terminal, not piped stdin).

## Environment Requirements

- Python 3.11+ with pytest
- Claude Code CLI (`claude` command)
- conda environment `llm` (or similar with pytest installed)
- Git (for SWE-bench repo cloning)
- ~500MB disk for SWE-bench repo cache

## Key Design Decisions

1. **eval.sh is independent of done.sh.** The agent writes done.sh as its
   own completion gate. eval.sh is ground truth written by the task author.
   They should agree, but eval.sh is authoritative.

2. **OPAL workspace uses CLAUDE.md auto-discovery.** The CLAUDE.md file in
   the workspace root tells Claude Code to read `.opal/harness.md`. No
   special flags needed.

3. **Parent CLAUDE.md must be renamed during runs.** Claude Code walks up
   the directory tree looking for CLAUDE.md. A parent directory's CLAUDE.md
   can interfere. The orchestrators handle this automatically.

4. **SWE-bench tasks use PYTHONPATH, not pip install.** `pip install -e .`
   of old project versions can corrupt the current environment. Instead,
   eval.sh sets `PYTHONPATH=$WORK_DIR` to make the project importable.

5. **Repo caching for SWE-bench.** First clone is blobless (60-80% smaller).
   Subsequent runs copy from `~/.cache/swebench-repos/`. Set
   `SWEBENCH_REPO_CACHE` to override the cache location.
