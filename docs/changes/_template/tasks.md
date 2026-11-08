# Tasks: <title>

Written by Claude Code in plan mode after reading `proposal.md` and the code, then approved by
the user. Deviations from the approved plan are recorded at the end of this file.

## Discrepancies between the proposal and the code

- <what the proposal assumes and what the code actually does; "None" if nothing>

## Technical design (L changes only)

Approach, data model, alternatives considered. Reasoning that should outlive this change
becomes an ADR in `docs/decisions/`.

## Files to touch

- `<path>`: <what changes>

## Steps

With several pull requests, start each step with the one that lands it: `(PR 1)`.

1. <step> → verify: <check>
2. <step> → verify: <check>

## Tests mapped to requirements

| Requirement | Test (name starts with the ID), or `Manual` and why no test is possible |
|---|---|
| <PREFIX>-n | `test/<path>_test.dart`: `'<PREFIX>-n: <behavior>'` |
| <PREFIX>-m | `Manual`: <why an automated test is not possible> |

## Before review

- [ ] Behavior changes merged into `docs/spec/features/`
- [ ] Area details updated in `docs/spec/areas/`
- [ ] Structure or patterns updated in `docs/spec/architecture.md`
- [ ] Dependency changes recorded in `docs/spec/tech-stack.md`
- [ ] Changed procedures updated in `docs/guides/`
- [ ] New decisions written as ADRs in `docs/decisions/`
- [ ] Design references updated (`docs/design/`, screen entries)
- [ ] Every requirement in the delta has a test named by its ID that asserts every THEN of its
      scenarios, or is on the `Manual` line of its feature file

## Before merge

- [ ] change-reviewer report: no open `blocker` or `should fix` findings
- [ ] Proposal content copied into the PR description, with the steps this pull request covers
- [ ] Last pull request of the change: this change folder deleted

## Deviations from the approved plan

- <date>: <what changed and why>
