# Proposal: <title>

Size: S | M | L (see "Scale by risk" in [docs/README.md](../../README.md)).
Folder: `docs/changes/<yyyy-mm-dd>-<slug>/`. May be written outside Claude Code. Its content
goes into the PR description, and the last PR of the change deletes the folder.

## Why

The problem or need, and who has it.

## Spec delta

Grouped by target spec file. A new requirement or screen takes the next free number of its
prefix; the number is reserved here. IDs are never reused.

### `docs/spec/features/<area>.md`

#### ADDED

- **<PREFIX>-n** <one sentence of observable behavior, present tense>
  - WHEN … THEN …

#### MODIFIED

Full new text of the requirement with all its scenarios, not a diff.

- **<PREFIX>-n** <new text>
  - WHEN … THEN …

#### REMOVED

- **<PREFIX>-n**: <reason>. The ID is added to the file's `Retired` line.

### `docs/spec/areas/<area>.md`, `docs/spec/architecture.md`, `docs/spec/tech-stack.md`

What changes in the implementation details, structure or dependencies. "None" if nothing.

## Design delta

Screenshots to add or replace under `docs/design/screens/<area>/<screen>--<state>.webp`, with
the Figma node or Claude Design link. "None" if the change has no visual part.

## Acceptance criteria

- [ ] <checkable statement, referring to requirement IDs>

## Out of scope

- <what this change does not do>

## Open questions

- <question, and who answers it>
