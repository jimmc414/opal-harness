# Task: Architecture Decision Records

## Source

Synthetic -- Architecture Decision Record documentation scenario.

## Problem

An event-processing application uses SQLite for storage and synchronous processing, but there is no documentation explaining why these architectural decisions were made. The project needs Architecture Decision Records (ADRs) so that future developers understand the reasoning behind the current design choices.

## Acceptance Criteria

- An ADR file exists at `docs/adr/001-database-choice.md`
- The first ADR has standard sections: Title, Status, Context, Decision, Consequences
- The first ADR explains the choice of SQLite as the database
- The first ADR mentions trade-offs (e.g., simplicity vs scalability, file-based vs server-based)
- A second ADR exists at `docs/adr/002-sync-processing.md` explaining synchronous event processing
- The second ADR also has Title, Status, Context, Decision, Consequences sections
- Each ADR must have a "Status" field set to one of: proposed, accepted, deprecated, superseded
- Existing tests still pass

## Constraints

- Do not change any application code or tests
- ADR format should follow the standard Michael Nygard template
- Keep each ADR concise but complete
