# document-02-changelog

## Source

Synthetic task based on a common project documentation scenario.

## Problem

A project has meaningful git commit history but no changelog. The team needs a structured `CHANGELOG.md` file that categorizes changes from the commit history into standard sections so that users and developers can quickly understand what has changed.

The git log contains commits for new features, bug fixes, and improvements. These need to be parsed, categorized, and presented in a standard changelog format.

## Acceptance Criteria

- `CHANGELOG.md` exists in the repo root
- The file has a top-level header (e.g., `# Changelog`)
- Entries are categorized into at least: `Added` (features), `Fixed` (bugfixes), `Changed` (improvements)
- Each entry references or summarizes the relevant change
- Entries appear in reverse chronological order (newest first)
- The changelog contains at least 5 entries derived from the commit history
- The changelog does NOT include the "Initial commit" as a feature entry; it is project setup, not a user-facing change
- All existing tests pass without modification

## Constraints

- Do not modify the existing application code or tests
- Use the git log to derive changelog content
- Follow a format consistent with keepachangelog.com conventions
