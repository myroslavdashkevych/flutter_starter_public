# ADR-016: every requirement has a test or a Manual entry

- Status: Accepted
- Date: 2026-11-07

## Context

Tests name the requirement they check ([docs/README.md](../README.md), Requirements), and
`tool/check_spec.dart` ([ADR-013](ADR-013-spec-driven-process.md)) checked the form of such a
name, but not whether a requirement had a test at all. The review checked tests only for the
requirements in a change's delta. Until the existing tests were renamed, no requirement was
traceable to a test, and a new requirement could land without one.

Some requirements cannot be checked by an automated test: the native splash is drawn by the
operating system before any Dart code runs, a launch from a system notification is system
behavior, and a requirement can state an absence. Their manual check lived only in a change's
`tasks.md`, which is deleted before merge.

## Decision

1. The `coverage` rule: every requirement (not a screen) starts a string literal in a
   `test/**/*.dart` file, alone or in an ID list (`'FAV-1, FAV-11: …'`), so a `group` name
   counts for all its tests; or the requirement is on the `Manual` line of its file. It is
   always on, also in CI.
2. A feature file may have one line `Manual: <IDs>` right before its `Retired` line. The
   requirement's scenarios are the manual check; no separate steps are written. The `manual`
   rule checks the line: its position, IDs of the file's prefix that are defined, not retired
   and listed once, and no ID that also has a test.
3. The change that puts an ID on a `Manual` line says why an automated test is not possible
   (in `tasks.md`); the change-reviewer checks this.
4. The rule started strict: the existing tests were renamed first, and the five requirements
   no test can check went to `Manual` lines: SPL-1, SPL-2 and SPL-3 (the native splash),
   NTF-8 (an Android launch from a system notification) and SET-8 (an absence: the usage-data
   switch does not affect notifications).

## Alternatives considered

- Report only, CI never fails: new requirements could still land without tests.
- Fail only for IDs added or changed since `--base`: once all tests were renamed, one strict
  rule is simpler than a mode tied to the base revision.
- A separate `docs/spec/manual-checks.md` with steps per ID: the scenarios already are the
  steps, and a second file drifts from the spec.
- A marker under each requirement: it changes the requirement format the linter parses, while
  a file-level line mirrors `Retired`.

## Consequences

- A requirement cannot land without its code and test, or without a stated reason for manual
  checking; a spec written ahead of its implementation fails CI.
- The rule counts a test named by an ID, not what it asserts: a test that covers a requirement
  only in part counts as coverage. Whether a test checks its requirement's scenarios stays with
  the review.
- A string literal that starts with an ID list counts wherever it appears in `test/`, not only
  as a `test` or `group` name: also in a `reason:`, a commented-out test or a skipped test. The
  review catches those.
- Revisit if the `Manual` lines grow: many entries would mean the spec describes behavior that
  tests cannot reach, or that tests are missing.
