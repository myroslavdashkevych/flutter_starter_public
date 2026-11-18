# Proposal: <title>

Size: S | M | L (see "Scale by risk" in [doc/workflow.md](../../workflow.md)).
Folder: `doc/change/<yyyy-mm-dd>-<slug>/`. May be written outside Claude Code. Its content
goes into the PR description, and the last PR of the change deletes the folder.

## Why

The problem or need, and who has it.

## Spec delta

Grouped by target spec file. A new requirement or screen takes the next free number of its
prefix; the number is reserved here. IDs are never reused.

### `doc/spec/behavior/<area>.md`

#### ADDED

- **<PREFIX>-n** <one sentence of observable behavior, present tense>
  - WHEN … THEN …

#### MODIFIED

Full new text of the requirement with all its scenarios, not a diff.

- **<PREFIX>-n** <new text>
  - WHEN … THEN …

#### REMOVED

- **<PREFIX>-n**: <reason>. The ID is added to the file's `Retired` line.

### `doc/spec/implementation/<area>.md`, `doc/spec/architecture.md`, `doc/spec/tech-stack.md`

What changes in the implementation details, structure or dependencies. "None" if nothing.

## Design delta

Screenshots to add or replace under `doc/design/screen/<area>/<screen>--<state>.webp`, with
the Figma node or Claude Design link. "None" if the change has no visual part.

## Acceptance criteria

- [ ] <checkable statement, referring to requirement IDs>

## Out of scope

- <what this change does not do>

## Open questions

- <question, and who answers it>
