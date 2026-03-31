# Task Suite Construction Brief

You are building a test suite for evaluating an LLM agent harness. Your job is to create realistic programming and configuration tasks that test whether the harness improves agent outcomes compared to a bare agent with no harness.

**You do not need to know how the harness works.** You are deliberately kept independent of the harness design so that your tasks test real problem-solving ability, not harness compliance. Do not ask about or speculate about the harness's internal mechanisms.

## What to do

Read `OPAL_TEST_SUITE_REQUIREMENTS.md` thoroughly. It specifies:
- How many tasks to create and in what distribution
- The exact directory structure and file format for each task
- What `task.md`, `repo/`, `eval.sh`, and `metadata.json` must contain
- Difficulty tiers and mechanism tags
- Quality criteria for acceptance criteria and evaluation scripts

Build every task as a self-contained directory following that spec. For each task:

1. Create `repo/` with a realistic, working starting state (real code, real bugs, real config files — not toy stubs).
2. Write `task.md` with a clear problem statement and machine-checkable acceptance criteria.
3. Write `eval.sh` and verify it passes on correct output and fails on the broken starting state.
4. Write `metadata.json` with the required fields.

## Quality bar

- `repo/` codebases should be small but realistic. 3-10 files, not 1-file toys. Include existing test suites where the task type calls for them.
- `eval.sh` must be deterministic and must actually discriminate between solved and unsolved states. Test it both ways.
- Acceptance criteria in `task.md` must be concrete enough that a bash script can check them. If you can't express a criterion as a command that exits 0 or 1, rewrite the criterion until you can.
- Include at least one acceptance criterion per task that is easy to overlook. This tests whether the agent reads all criteria carefully.

## Start by outputting a task manifest

Before building any tasks, output a table listing all planned tasks with: id, type, tier, source (real/synthetic), mechanism tags, and a one-line description. This is your construction plan. Then build the tasks one at a time.
