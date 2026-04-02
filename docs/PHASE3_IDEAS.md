# Phase 3 Ideas: Beyond Binary Pass/Fail

## Context

Phase 1 (5 synthetic tasks) and Phase 2 (5 SWE-bench sympy bugs) both showed
Opus solving every task in both bare and OPAL conditions. OPAL added ~40% cost
overhead with no pass-rate improvement. The tasks were too easy — Opus solves
them on the first try, so OPAL's recovery/planning mechanisms never activate.

**The open question:** What kind of task would actually differentiate bare vs
OPAL? Two requirements:
1. Complex enough that Opus won't fully solve it in one shot
2. Success is on a spectrum, not binary — we can measure *how far* each
   condition got, even when both fail

## Why Binary Eval Doesn't Work Here

SWE-bench and our synthetic tasks evaluate: "did the fix work? yes/no." This
tests whether the agent can find and fix a single bug. Opus is good at that.
OPAL's value isn't in single-bug fixing — it's in maintaining coherence over
long, ambiguous tasks where:
- The agent must plan before acting
- Mid-course correction matters
- Context management (what's done, what's left, what failed) is load-bearing
- The task is too large for working memory

## Candidate Task Types

### 1. Major Refactor with Graded Rubric

Give the agent a real 800+ line Python file and say: "decompose this into a
well-structured package."

**Why it's good for OPAL:** Requires planning (where to split?), tracking
(what's moved, what's left?), and verification (do imports still work?).

**Graded scoring (0-10):**
- Module boundaries are logical (0-3)
- Public API preserved / tests pass (0-2)
- Import graph is clean, no cycles (0-1)
- New files are individually coherent (0-2)
- README/docstrings updated (0-1)
- No dead code or leftover imports (0-1)

**Challenge:** Finding the right source file. Needs to be complex enough to
require multiple decisions but small enough to fit in context.

### 2. Greenfield Feature Checklist

"Implement a markdown-to-HTML converter supporting these 12 features."

Each feature is independently testable:
1. Headings (h1-h6) 
2. Paragraphs
3. Bold/italic
4. Links
5. Images
6. Unordered lists
7. Ordered lists
8. Code blocks (fenced)
9. Inline code
10. Blockquotes
11. Horizontal rules
12. Nested lists

**Score = features passing / 12.** Neither condition will get all 12 perfectly.
OPAL might get 9 because it planned and tracked completion. Bare might get 7
because it lost track of what was left to implement.

**Why it's good for OPAL:** The plan.md checklist maps directly to features.
The agent must track which features are done. done.sh can test each one.

### 3. "Continue This Half-Done PR"

Give the agent a codebase where someone started a refactor and abandoned it.
Some files are converted, some aren't, there are TODOs everywhere, and tests
are partially broken. Task: finish it.

**Why it's good for OPAL:** This is pure state management. The ORIENT phase
forces the agent to understand what's already done before acting. state.md
tracks progress. Dead Ends captures what the original developer tried and
abandoned.

**Scoring:**
- Files correctly migrated / total files needing migration
- Tests passing / total tests
- TODOs resolved / total TODOs
- No regressions introduced

### 4. The "Messy Spec" Task

Give the agent a real GitHub issue thread — not the cleaned-up problem
statement, but the actual discussion with contradictory suggestions, red
herrings, and evolving requirements. Task: implement what the users need.

**Why it's good for OPAL:** Tests ORIENT phase quality. Did the agent extract
the actual requirement from the noise? OPAL's plan.md "Revised Understanding"
section captures how the agent's understanding evolved.

### 5. Multi-Module Integration Task

"This project has 5 modules that each work independently. Wire them together
into a working application with a CLI interface, error handling, and a test
suite."

**Scoring:**
- Modules correctly integrated (0-5)
- CLI works for basic operations (0-3)
- Error paths handled (0-3)
- Test coverage exists (0-2)
- Configuration works (0-2)

**Why it's good for OPAL:** Cross-module work requires tracking dependencies
and sequencing changes correctly.

## The Best Candidate (Current Thinking)

**Option 2 (Greenfield Feature Checklist)** is the strongest for several reasons:

1. **Objective scoring:** Each feature has a test. No subjective rubric.
2. **Scalable difficulty:** 12 features means partial completion is expected.
3. **Clean experimental design:** Both conditions start from zero. No existing
   codebase variance to control for.
4. **OPAL advantage is testable:** The plan.md checklist should directly map to
   features. done.sh should test each feature. This is what OPAL is designed for.
5. **Easy to implement:** We write the test suite upfront. The agent implements
   the code. Eval runs the tests. Score = tests passing.

**Runner-up: Option 3 (half-done PR)** because it tests state management —
OPAL's core value proposition — in the most direct way possible.

## Graded Eval Framework

For any task type, replace binary eval.sh with a graded eval:

```bash
#!/usr/bin/env bash
# Graded eval: reports score 0-N instead of pass/fail
SCORE=0
TOTAL=0

run_check() {
    local name="$1"; shift
    TOTAL=$((TOTAL + 1))
    if "$@" >/dev/null 2>&1; then
        SCORE=$((SCORE + 1))
        echo "PASS: $name"
    else
        echo "FAIL: $name"
    fi
}

run_check "Feature: headings" python -m pytest tests/test_headings.py -x -q
run_check "Feature: paragraphs" python -m pytest tests/test_paragraphs.py -x -q
run_check "Feature: bold/italic" python -m pytest tests/test_emphasis.py -x -q
# ... etc

echo "SCORE: $SCORE / $TOTAL"
echo "$SCORE" > "$RESULT_DIR/score"
```

## OPAL-Specific Progress Signals

Even on failed tasks, OPAL produces structured artifacts that bare does not:

| Signal | What it tells us | Bare equivalent |
|--------|-----------------|-----------------|
| state.md final phase | How far did the agent get? | Parse transcript (expensive) |
| plan.md checkboxes | Which steps were completed? | Nothing |
| log.md entries | What was attempted in what order? | Parse transcript |
| Dead Ends section | What was tried and abandoned? | Nothing |
| done.sh criteria | Did the agent understand the requirements? | Nothing |
| Cycle count | How much effort was spent? | Turn count (less structured) |

This means OPAL provides richer failure analysis even when both conditions fail.

## Next Steps

1. Pick one task type (likely Option 2: feature checklist)
2. Build the test suite and graded eval
3. Run Phase 3: bare vs OPAL on a single hard task
4. Compare scores, not just pass/fail
