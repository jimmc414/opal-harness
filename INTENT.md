# Intent

Most agent frameworks are designed by humans, for humans, and then imposed on LLMs. The LLM is the thing being orchestrated — it doesn't get a vote in how the orchestration works.

OPAL asks a different question: **what does the agent harness look like if you design it from the LLM's perspective?**

This project started with a simple prompt to Claude: "What would be the most intuitive harness design from your perspective? What makes the most sense to you? How would you like this laid out?" The answer became the spec. Not because an LLM's preferences are automatically correct, but because the LLM is the one that has to follow the protocol — and a protocol the agent finds natural to follow will work better than one it has to be forced into.

## What Claude said it needed

When asked directly, a few things came back clearly:

**"I'm bad at knowing when to stop."** This is the single biggest failure mode. Without a concrete, checkable completion condition, the agent will keep polishing, exploring, or adding verification layers that don't converge. The answer was `done.sh` — a bash script that exits 0 or 1. The agent can't declare itself done until the check passes. No vibes. No "looks good to me."

**"Tell me where I am before telling me what to do."** Most frameworks front-load instructions: pages of role definitions, tool descriptions, and behavioral rules before the agent ever learns what task it's working on or what state it's in. Claude said it wanted the opposite — read a short state file first (where am I, what's done, what's next), then the task, then the plan, then the instructions. Context position matters. The most important information should come first.

**"I forget what I tried."** After context truncation, the agent loses memory of failed approaches and will re-attempt them. The fix is simple: a `Dead Ends` section in the plan file, written to disk, that survives truncation. Not sophisticated. Just persistent.

**"Don't make me pretend to be multiple people."** Multi-agent orchestration and role-switching ("now you're the solver, now you're the verifier") are cognitively expensive. Each switch requires rebuilding context about what role the agent is in and what success means from that role's perspective. Claude preferred a single coherent perspective throughout, with clear phase transitions instead of persona changes.

**"Don't let me explore speculatively."** Given latitude, the agent will generate alternative approaches "just in case." Multi-candidate search sounds good in theory but in practice produces alternatives the agent can't meaningfully rank. The preference was clear: try your best approach, check if it works, re-plan only on failure.

## What this project is trying to find out

The honest answer: we don't know if any of this works yet.

The spec is well-reviewed. The test suite is built. But zero tasks have been run. The hypothesis is that an LLM-designed harness will be more naturally followed and produce better outcomes than no harness at all, particularly on tasks that require recovery from failed first attempts.

That hypothesis could be wrong. The agent might read harness.md, say "understood," and then do exactly what it would have done anyway. The overhead of maintaining state files and writing completion checks might slow down easy tasks without helping hard ones. The completion gate might be a fiction if the agent writes trivial checks that always pass.

We've defined concrete conditions under which we'd abandon the approach. This is research, not advocacy.

## What this could become

If the hypothesis holds — if agents follow the protocol naturally and it improves outcomes on recovery-heavy tasks without degrading simple ones — then OPAL could become a lightweight, portable standard for how LLM agents manage multi-step work.

Not a framework. Not a library. A convention. A workspace layout and a set of operating rules simple enough to fit in a single file, agent-agnostic enough to work with any model or tool surface, and grounded enough in how LLMs actually process context that agents follow it because it makes sense to them — not because they've been instructed to comply.

The aspiration is that OPAL becomes to agent task management what `.gitignore` is to version control or `Makefile` is to builds: a file you drop into a project that just works, because the conventions it encodes match the way the tool naturally wants to operate.

That's aspirational. We'll see what the data says.

## How this was made

The spec was developed through adversarial collaboration between two Claude instances — one on claude.ai (extended thinking, design-oriented) and one in Claude Code (implementation-oriented, reviewing and stress-testing). They disagreed on real things: whether orientation cycles should count against the budget, whether error taxonomies add value, whether repair caps should be configurable. Each disagreement resolved toward the stronger argument regardless of which instance proposed it.

The test tasks were written by a third Claude Code instance that was deliberately given no knowledge of the harness design. It received only the test suite requirements document. This separation ensures the tasks test real problem-solving, not harness compliance.

A human (Jim) orchestrated the process, made judgment calls at decision points, and kept the collaboration productive. The design is Claude's. The decisions about what to ship are Jim's.
