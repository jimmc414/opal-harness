# Refactor: Split Monolithic Game Engine Module

## Source

Synthetic task modeling a common codebase maintenance scenario: breaking a monolithic module into cohesive, single-responsibility sub-modules.

## Problem

The `gamelib/engine.py` file contains four distinct subsystems (rendering, physics, input handling, and audio) plus a top-level `GameEngine` orchestrator, all in a single file. As the codebase grows, this monolith makes it difficult to navigate, test in isolation, and assign ownership. Each subsystem should live in its own module.

## Acceptance Criteria

- `engine.py` is split into at least four sub-modules: `rendering.py`, `physics.py`, `input.py`, and `audio.py`
- The `GameEngine` class moves to its own module (e.g., `core.py`) or remains in a reduced `engine.py` that only contains the orchestrator
- `gamelib/__init__.py` re-exports every name that was previously importable, so `from gamelib import Renderer, PhysicsBody, ...` continues to work unchanged
- The original monolithic `engine.py` either no longer exists or contains only the `GameEngine` class (not the full monolith)
- All existing tests pass without any modifications to test import statements
- Internal cross-module references work correctly (e.g., `resolve_collision` calling `check_collision`, and `GameEngine.update` calling `apply_gravity` and `resolve_collision`)

## Constraints

- Do not modify any test file
- Do not rename any class, function, or parameter
- The `math` import should only appear in modules that use it
- Every name currently exported from `gamelib/__init__.py` must remain importable from `gamelib`
