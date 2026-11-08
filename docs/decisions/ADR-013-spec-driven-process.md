# ADR-013: spec-driven process in plain Markdown with our own linter

- Status: Accepted
- Date: 2026-11-07

## Context

The starter is an existing app, and every new project begins as a copy of it. Its docs needed
a living spec of how the app works now, short-lived change folders, ADRs, design conventions
and requirement IDs that tests can name. The migration brief asked for plain Markdown without
an external CLI. The tools below were compared from memory, not against their current documentation.

## Decision

1. The spec, change folders and their templates are plain Markdown in `docs/`, with the
   conventions in `docs/README.md` and the change workflow in `CLAUDE.md`.
2. `tool/check_spec.dart` (Dart, run in CI like `tool/check_imports.dart`) checks the
   conventions: requirement format, scenarios, unique IDs, the `Retired` line, no gaps in
   numbering, ID references, test names and relative links.

## Alternatives considered

- GitHub Spec Kit: built to go from a new feature's spec to code. Its specs belong to single
  changes and do not merge into one living spec, each feature needs many files, and it needs a
  Python CLI.
- OpenSpec: the closest model (living specs plus change deltas, with `validate` and `archive`).
  Rejected because it adds a Node CLI to a Flutter repository, developer machines and CI; it
  has no requirement IDs for tests, no ADRs, design or source-of-truth rule; and its format
  changes between versions, which every project copied from this template would inherit.

## Consequences

- The process holds only if the linter runs: without it the spec drifts back to free text.
- The linter is our code: it needs tests and maintenance, and every project created from the
  template inherits it.
- Merging a change's delta into the spec stays manual, done in the same pull request.
- Revisit if the brief's "no external CLI" constraint is dropped, or if keeping the linter costs more
  than a maintained tool would.
