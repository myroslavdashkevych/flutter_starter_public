# ADR-015: check removed requirement IDs against the base branch

- Status: Accepted
- Date: 2026-11-07

## Context

Requirement and screen IDs are never reused ([docs/README.md](../README.md), Requirements).
`tool/check_spec.dart` ([ADR-013](ADR-013-spec-driven-process.md)) checked this only through
the `gap` rule: defined plus retired IDs are exactly `1..max`, where `max` is the highest ID in
the files. Deleting the highest requirement or screen without retiring it lowers `max` and
passes, and an ID taken off the `Retired` line and defined again passes too. Either frees a
number for reuse, and only a reviewer could notice it in a diff.

## Decision

1. `tool/check_spec.dart --base <rev>` reads `docs/spec/features/*.md` of that git revision and
   runs the `removed` rule: every ID defined there is still defined or retired, and every ID
   retired there is still retired. A prefix that no feature file uses any more is skipped (a
   deleted area). Without `--base` the linter runs no git.
2. CI passes the base: the target branch on a pull request, the previous tip on a push to
   `main` or `develop`. Checkout fetches the full history for this.

## Alternatives considered

- `Next ID` counters in every feature file, checked without git: rejected because every file
  keeps state by hand, and a counter lowered together with a deleted ID still passes.
- A separate CI step that parses the diff for removed requirement lines: the same result with
  a second tool, and a requirement moved within a file looks like a removal.
- A registry of issued IDs: a counter by another name.
- Requiring a test per requirement, so the `reference` rule fails on a removed ID: partial
  (removing the tests with it passes), and it is a separate decision about coverage.
- Review only: the gap this decision closes.

## Consequences

- The linter depends on git when `--base` is given; an unknown revision exits 2, so CI fails
  instead of skipping the check. A force push to `main` or `develop` can make the previous tip
  unavailable and fail the push run. A revert that drops requirements without retiring them
  fails like any other removal.
- The check runs in CI, not before a commit; locally it runs with `--base develop`.
- Two parallel changes that take the same new number are not caught here, or in review: the
  unique-ID check catches them in a CI run made after the other change merged
  ([guides/setup.md](../guides/setup.md), Branch protection).
- Revisit if CI stops fetching history or the base branch changes name.
