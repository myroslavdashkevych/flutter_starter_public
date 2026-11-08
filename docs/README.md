# Documentation

The specification in `spec/` describes how the app works **now**. Every behavior change
updates it in the same pull request. Plans live only while a change is in flight.

## Map

| Path | What it holds | Changes when |
|---|---|---|
| [reading-rules.md](reading-rules.md) | Reading rules for agents: what to read for which change | A document is added, moved or split |
| [spec/product.md](spec/product.md) | Vision, users, scope, non-goals, localization | Scope changes |
| [spec/features/](spec/features/) | One file per area: requirements with IDs and scenarios, screens | Any behavior change |
| [spec/areas/](spec/areas/) | Implementation details per area: contracts, data sources, storage keys, wiring | Area internals change |
| [spec/architecture.md](spec/architecture.md) | Rules every change needs: layers, folders, import rules, data flow, and one section per cross-cutting pattern (errors, DI, networking, storage, state, routing, logging, naming, testing) | Structure or a pattern changes |
| [spec/tech-stack.md](spec/tech-stack.md) | Approved dependencies, compatibility notes | `pubspec.yaml` changes |
| [decisions/](decisions/) | ADRs: why a decision was made, what was rejected | A decision is made or replaced |
| [design/](design/README.md) | Approved screen designs and design conventions | A design is approved |
| [changes/](changes/) | One folder per change in flight; deleted by its last pull request | During a change |
| [guides/](guides/) | How-tos: [setup](guides/setup.md), [new project](guides/new-project.md), [store release](guides/store-release.md) | A procedure changes |

## Source of truth

- The **spec** owns behavior, states, texts and navigation.
- The **design** (`design/screens/`) owns the look.
- **Theme tokens in code** (`lib/presentation/_shared/theme`) own colors, typography, spacing
  and sizes.

When two of them disagree, when the spec and the code disagree, or when a built screen differs
from its approved design, stop and ask the user. Never resolve a conflict silently.

## Requirements

- **IDs.** An area prefix and a number: `NAV`, `AUTH`, `ITM`, `PRF`, `SET`, `NTF`, `OBS`,
  `SPL`, `FAV`. Each requirement is one observable behavior.
- **Never reused.** A removed requirement is deleted from the spec and its ID is added to the
  `Retired` line at the end of its file, and stays there for good. A new ID takes the next free
  number and is reserved in the change's `proposal.md`. Two changes in flight may reserve the
  same number; the review sees only its own branch and cannot notice. CI catches it with the
  unique-ID check, but only in a run made after the other change merged: a pull request's CI
  result must be newer than the last merge into `develop` ([guides/setup.md](guides/setup.md),
  Branch protection). The change that merges second renumbers its IDs, together with its test names
  and references, since no check notices a test that still names the old ID.
- **Format.** The ID in bold, one sentence of behavior in the present tense, and at least one
  scenario (`WHEN … THEN …`, with `GIVEN` when there is a precondition):

  ```
  - **FAV-2** A guest sees no favorite toggles.
    - WHEN a guest opens the items list THEN no tile shows a favorite toggle
  ```

- **Vague spots** are marked inline: `[NEEDS CLARIFICATION: <question>]`. Before changing a
  requirement that carries a marker, ask the user.
- **Implementation notes** in a feature file hold only facts that explain an observable
  behavior. Everything else about how an area works goes to `spec/areas/<area>.md`.
- **Tests** name the requirement they check: `'FAV-2: guest sees no toggle'`; a test that
  checks several lists them: `'FAV-1, FAV-11: adding sends the event'`. A `group` name may
  carry the IDs for all its tests. Every requirement has at least one such test, or its ID is
  on the `Manual` line of its feature file. `check_spec` checks only the names; the review reads
  the tests of the requirements in a change's delta and checks that every THEN is asserted.
- **Manual checks.** A requirement that no automated test can reasonably check is listed on
  one `Manual` line right before the `Retired` line of its feature file
  (`Manual: SPL-1, SPL-2, SPL-3`; a file without such requirements has no `Manual` line). Its
  scenarios are the manual check; no separate steps are written. The change that adds an ID
  there says why it cannot be automated (in `tasks.md`, or in the review prompt for a change
  without a folder). When a test for it appears, the ID leaves the line.
- **Checked** by `tool/check_spec.dart`, also in CI: requirement and screen format, scenarios,
  unique IDs, the `Retired` line, no gaps in numbering, ID references in docs and code, and
  test names ([ADR-013](decisions/ADR-013-spec-driven-process.md)); every requirement has a test
  or a `Manual` entry, and the `Manual` line is well formed
  ([ADR-016](decisions/ADR-016-requirement-coverage.md)). With `--base <rev>` (in CI:
  the target branch, or the previous tip on a push) it also checks that no ID defined or retired
  in that revision disappeared or left the `Retired` line; locally:
  `fvm dart run tool/check_spec.dart --base develop`
  ([ADR-015](decisions/ADR-015-removed-id-check.md)).

## Screens

Each screen has a global ID `SCR-n`, defined in the feature file that owns it, with its route,
its states and the requirement IDs they relate to, and a design line:

- `Design: pending`: no approved design; the screen uses theme tokens and shared widgets only.
- Later: a path under `design/screens/` plus a Figma node link or a Claude Design link.

## Changes

Every change, of any size, goes on its own branch from `develop`, named `<type>/<slug>` with the
type of its commit prefix, and reaches `develop` through a pull request. `main` receives only
merges from `develop`. Commit messages are Conventional Commits in English: `feat:`, `fix:`,
`refactor:`, `test:`, `docs:`, `chore:`, `ci:`.

1. **Proposal** (`changes/<yyyy-mm-dd>-<slug>/proposal.md`, from
   [the template](changes/_template/proposal.md)): why, the spec delta grouped by target file
   (ADDED / MODIFIED with the full new text / REMOVED), design delta, acceptance criteria, out
   of scope, open questions. It may be written outside Claude Code.
2. **Tasks** (`tasks.md`, from [the template](changes/_template/tasks.md)): written by Claude
   Code in plan mode after reading the code, approved by the user. Discrepancies between the
   proposal and the code come first; deviations from the approved plan are recorded at the end.
3. **Implement** with tests named by requirement IDs. In the same pull request, merge the delta
   into `spec/`, write ADRs for durable reasoning and update the other docs ("Before review" in
   [the tasks template](changes/_template/tasks.md)), so the review sees the final spec. A
   large change may land in several pull requests: each merges the part of the delta it
   implements, so `develop` keeps a spec that matches the code, and `tasks.md` marks each step
   with the pull request that lands it (`(PR 1)`). Then run Verification (below).
4. **Review** by the `change-reviewer` agent
   ([.claude/agents/change-reviewer.md](../.claude/agents/change-reviewer.md), checklist and
   parameters there; [ADR-014](decisions/ADR-014-change-reviewer.md)). It reports; the main
   session fixes. Size S changes are reviewed too, without a change folder.
5. **Before merge:** the proposal goes into the description of every pull request of the
   change, with the steps that pull request covers, and the last one deletes the change folder. Git history and the PRs keep the record; there is no
   archive folder. CI warns while a change folder exists, so a forgotten one stays visible.

### Verification

Before a change is called done:

1. If annotated classes or ARB files changed: `fvm dart run build_runner build` /
   `fvm flutter gen-l10n`
2. `fvm flutter analyze` (no issues)
3. `fvm dart run tool/check_imports.dart` and `fvm dart run tool/check_spec.dart --base develop`
4. `fvm flutter test`
5. `fvm dart format` on changed files only
6. New user-facing strings exist in both `app_en.arb` and `app_uk.arb`
7. Docs match the change: the "Before review" list of
   [the tasks template](changes/_template/tasks.md)

### Scale by risk

| Size | Examples | Process |
|---|---|---|
| S | Bug fix that restores specified behavior, typo, refactor without behavior change | No change folder; a regression test named by the broken requirement's ID that asserts the broken THEN; the "Before review" list of the tasks template still applies |
| M | Small behavior change, structural refactor | Short proposal and tasks |
| L | New feature, architecture, data model | Full proposal, research, ADRs |

Only the three kinds listed for S go without a change folder; any behavior change is M or L.
Any behavior change updates the spec, whatever its size.

## ADRs

[decisions/_template.md](decisions/_template.md): context, decision, alternatives considered,
consequences, status (`Accepted` or `Superseded by ADR-nnn`). An ADR is never rewritten; a new
decision supersedes it. Only its links may be fixed when their target moves.

## Links

Link to a file and name the heading ("`guides/setup.md`, Flavors"). Do not refer to
section numbers: they change when a document is reorganized. `tool/check_spec.dart` checks
that relative links point to an existing file and heading; links inside `changes/` are not
checked.
