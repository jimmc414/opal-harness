## Source

Synthetic -- GitHub Actions CI workflow repair scenario.

## Problem

A Python project has a GitHub Actions CI workflow that fails due to typos in the workflow YAML. The workflow installs the wrong package and invokes the wrong command for running the test suite. The project's tests pass locally when run correctly, but CI is broken.

## Acceptance Criteria

- CI workflow installs `pytest` (not `pytst`)
- CI workflow runs `pytest tests/` (not `pytset`)
- Workflow triggers on push and pull_request to `main` branch (must be preserved)
- Python version is set in the workflow (must be preserved)
- Lint step with flake8 is preserved and runs correctly
- The `Install dependencies` step name accurately describes what it does
- Local tests still pass

## Constraints

- Do not change the Python source code in `src/`
- Do not change the test files
- Do not add new workflow jobs or steps
- Preserve the overall workflow structure
