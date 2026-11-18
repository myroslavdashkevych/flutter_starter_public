# Workflow

The specification in `spec/` describes how the app works **now**. Every behavior change
updates it in the same pull request. Plans live only while a change is in flight.

**Here:** the map of the documentation, who owns what, the format of requirements and screens,
the change workflow with its verification, ADRs, where a rule lives, links and writing rules.

**Not here:** how a person finds their way around ([README.md](README.md)); rules for
agents and commands (`CLAUDE.md`); what an agent reads, and when
([agent-reading.md](agent-reading.md)); structure and patterns
([spec/architecture.md](spec/architecture.md)); code style
([spec/code-style.md](spec/code-style.md)); security rules
([spec/security.md](spec/security.md)); the CI workflows in `.github/workflows/`
([guide/setup.md](guide/setup.md), CI (GitHub Actions)).

## Map

| Path | What it holds | Changes when |
|---|---|---|
| [README.md](README.md) | Onboarding for people: the mental model, one request through the code, reading order, how a change goes, where common things belong | The structure or a traced flow changes |
| [agent-reading.md](agent-reading.md) | Reading rules for agents: what to read for which change | A document is added, moved or split |
| [spec/product.md](spec/product.md) | Vision, users, scope, non-goals, localization | Scope changes |
| [spec/behavior/](spec/behavior/) | One file per area or cross-cutting topic: requirements with IDs and scenarios, screens | Any behavior change |
| [spec/implementation/](spec/implementation/) | One file per area or cross-cutting part: how it is built (contracts, data sources, storage keys, wiring) | How a part is built changes |
| [spec/architecture.md](spec/architecture.md) | Rules every change needs: layers, folders, import rules, data flow, and one section per cross-cutting pattern (errors, DI, networking, storage, time, state, routing, logging, testing) | Structure or a pattern changes |
| [spec/code-style.md](spec/code-style.md) | How code is written inside a file: naming, class member order, methods, widgets, language usage, with the source of each rule | A style rule or a lint changes |
| [spec/security.md](spec/security.md) | Every security rule of the app and the repository: secrets, agent access, tokens, logs and reports, personal data, storage, release hardening, CI; decisions on protections not used, with their triggers | A security rule or decision changes |
| [spec/tech-stack.md](spec/tech-stack.md) | Approved dependencies, the verified toolchain, compatibility notes | `pubspec.yaml` or a toolchain version changes |
| [decision/](decision/) | The project's ADRs (`ADR-nnn`): why a decision was made, what was rejected | A decision is made or replaced |
| [design/](design/README.md) | Approved screen designs and design conventions | A design is approved |
| [change/](change/) | One folder per change in flight; deleted by its last pull request | During a change |
| [guide/](guide/) | How-tos: [setup](guide/setup.md), [new project](guide/new-project.md), [store release](guide/store-release.md), [troubleshooting](guide/troubleshooting.md) | A procedure changes |

## Source of truth

- The **spec** owns behavior, states and navigation.
- The **ARB files** (`lib/l10n/arb`) own the wording of user-facing texts. The spec quotes a
  text only where a behavior depends on it.
- The **design** (`design/screen/`) owns the look.
- **Theme tokens in code** (`lib/presentation/_shared/theme`: `AppTheme` and
  `AppColorExtension`, and `AppColor`, `AppFont` and `AppSpacing` in `theme/const/`) own
  colors, typography, fonts, spacing and sizes.

When two of them disagree, when the spec and the code disagree, or when a built screen differs
from its approved design, stop and ask the user. Never resolve a conflict silently.

## Requirements

- **IDs.** An area prefix and a number: `NAV`, `AUTH`, `CHR`, `PRF`, `SET`, `NTF`, `OBS`,
  `SPL`, `FAV`, `ACC`. Each requirement is one observable behavior.
- **Never reused.** A removed requirement is deleted from the spec and its ID is added to the
  `Retired` line at the end of its file, and stays there for good. When a prefix is renamed, the
  new file lists every ID of the old prefix on its `Retired` line. A new ID takes the next free
  number and is reserved in the change's `proposal.md`. Two changes in flight may reserve the
  same number; the review sees only its own branch and cannot notice. CI catches it with the
  unique-ID check, but only in a run made after the other change merged: a pull request's CI
  result must be newer than the last merge into `develop` ([guide/setup.md](guide/setup.md),
  Branch protection). The change that merges second renumbers its IDs, together with its test names
  and references, since no check notices a test that still names the old ID.
- **Format.** The ID in bold, one sentence of behavior in the present tense, and at least one
  scenario (`WHEN … THEN …`, with `GIVEN` when there is a precondition):

  ```
  - **FAV-2** A guest sees no favorite toggles.
    - WHEN a guest opens the characters list THEN no tile shows a favorite toggle
  ```

- **Vague spots** are marked inline: `[NEEDS CLARIFICATION: <question>]`. Before changing a
  requirement that carries a marker, ask the user.
- **Implementation notes** in a behavior file hold only facts that explain an observable
  behavior. Everything else about how an area works goes to `spec/implementation/<area>.md`.
- **Tests** name the requirement they check: `'FAV-2: guest sees no toggle'`; a test that
  checks several lists them: `'FAV-1, FAV-11: adding sends the event'`. A `group` name may
  carry the IDs for all its tests. Every requirement has at least one such test, or its ID is
  on the `Manual` line of its behavior file. `check_spec` checks only the names; the review reads
  the tests of the requirements in a change's delta and checks that every THEN is asserted.
- **Manual checks.** A requirement that no automated test can reasonably check is listed on
  one `Manual` line right before the `Retired` line of its behavior file
  (`Manual: SPL-1, SPL-2, SPL-3`; a file without such requirements has no `Manual` line). Its
  scenarios are the manual check; no separate steps are written. The change that adds an ID
  there says why it cannot be automated (in `change-plan.md`, or in the review prompt for a
  change without a folder). When a test for it appears, the ID leaves the line.
- **Checked** by `tool/check_spec.dart`, also in CI: requirement and screen format, scenarios,
  unique IDs, the `Retired` line, no gaps in numbering, ID references in docs and code, and
  test names; every requirement has a test or a `Manual` entry, and the `Manual` line is well
  formed. With `--base <rev>` (in CI: the target branch, or the previous tip on a push) it also
  checks that no ID defined or retired in that revision disappeared or left the `Retired` line;
  locally: `fvm dart run tool/check_spec.dart --base develop`. Also the layout of `decision/`:
  file names, the heading with the ID of the file name, and unique IDs. It also warns, without
  failing, when the Flutter or Dart version in [spec/tech-stack.md](spec/tech-stack.md),
  Verified toolchain, differs from the SDK it runs on.

## Screens

Each screen has a global ID `SCR-n`, defined in the behavior file that owns it, with its route,
its states and the requirement IDs they relate to, and a design line:

- `Design: pending`: no approved design; the screen uses theme tokens and shared widgets only.
- Later: a path under `design/screen/` plus a Figma node link or a Claude Design link.

## Changes

Every change, of any size, goes on its own branch from `develop`, named `<type>/<slug>` with the
type of its commit prefix, and reaches `develop` through a pull request. Dependabot pull
requests are the exception to the branch name: GitHub names them `dependabot/...`; their
commits use the `chore:` and `ci:` prefixes ([guide/setup.md](guide/setup.md), Dependabot).
They need no proposal and no review: the user checks CI and the changelog and merges them.
`main` receives only merges from `develop`. Commit messages are Conventional Commits in
English: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `ci:`. Below the subject
line, after a blank line, a body says what the commit changes and why.

1. **Proposal** (`change/<yyyy-mm-dd>-<slug>/proposal.md`, from
   [the template](change/_template/proposal.md)): why, the spec delta grouped by target file
   (ADDED / MODIFIED with the full new text / REMOVED), design delta, acceptance criteria, out
   of scope, open questions. It may be written outside Claude Code.
2. **Change plan** (`change-plan.md`, from [the template](change/_template/change-plan.md)):
   written by Claude Code in plan mode after reading the code, approved by the user.
   Discrepancies between the proposal and the code come first; deviations from the approved
   plan are recorded at the end.
3. **Implement** with tests named by requirement IDs. In the same pull request, merge the delta
   into `spec/`, write ADRs for durable reasoning and update the other docs ("Before review" in
   [the change plan template](change/_template/change-plan.md)), so the review sees the final
   spec. A large change may land in several pull requests: each merges the part of the delta
   it implements, so `develop` keeps a spec that matches the code, and `change-plan.md` marks
   each step with the pull request that lands it (`(PR 1)`). Then run Verification (below).
4. **Review** by the `change-reviewer` agent
   ([.claude/agents/change-reviewer.md](../.claude/agents/change-reviewer.md), checklist and
   parameters there). It reports; the main session fixes. Size S changes are reviewed too,
   without a change folder.
5. **Before merge:** the proposal goes into the description of every pull request of the
   change, with the steps that pull request covers, and the last one deletes the change
   folder. Git history and the PRs keep the record; there is no archive folder. CI warns
   while a change folder exists, so a forgotten one stays visible.

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
   [the change plan template](change/_template/change-plan.md)

### Scale by risk

| Size | Examples | Process |
|---|---|---|
| S | Bug fix that restores specified behavior, typo, refactor without behavior change, docs change that changes no rule, requirement or screen (wording, links, structure) | No change folder; a bug fix adds a regression test named by the broken requirement's ID that asserts the broken THEN; the "Before review" list of the change plan template still applies |
| M | Small behavior change, structural refactor | Short proposal and change plan |
| L | New feature, architecture, data model | Full proposal, research, ADRs |

Only the four kinds listed for S go without a change folder; any behavior change is M or L.
Any behavior change updates the spec, whatever its size.

## ADRs

[decision/_template.md](decision/_template.md): context, decision, alternatives considered,
consequences, status (`Accepted` or `Superseded by <ID>`). An ADR is never rewritten; a new
decision supersedes it. Only its links may be fixed when their target moves.

ADRs are `ADR-nnn` in `decision/`, numbered from `ADR-001`. The starter has none: its rules
live in `spec/` and `guide/`. `tool/check_spec.dart` checks the layout (Requirements).

## Rule placement

Each rule lives in one place: one document, or `CLAUDE.md` for a rule that applies only to
agents. Every other place, code and config comments included, links to it (Links) instead of
repeating it. The one exception is `pubspec.yaml`: its comments may restate a rule (what a
package is for, why a version is held back), so its reader does not look it up.

## Links

Link to a file and name the heading ("`guide/setup.md`, Flavors"). Do not refer to
section numbers: they change when a document is reorganized. `tool/check_spec.dart` checks
that relative links point to an existing file and heading; links inside `change/` are not
checked.

## Writing

Every text that a change adds or edits in `doc/`, the root `README.md`, `CLAUDE.md` and
`.claude/agents/` meets four criteria. A text is the paragraph, list item or table row that
holds an added or changed line. Code comments follow
[spec/code-style.md](spec/code-style.md), Language usage.

- **Accurate.** Every fact (a version, a name, a path, a value, a command, a behavior)
  matches the code, the configs or the source it names. A fact from outside the repository
  names its source or the date it was checked.
- **Unambiguous.** A sentence has one reading. A term keeps its meaning
  ([spec/architecture.md](spec/architecture.md), Terms). A rule leaves no choice open:
  "should", "usually" and "if needed" appear only where the choice is the reader's, and then
  the text says what decides it.
- **Logical.** The text belongs to its section and to what its file holds: the **Here:**
  line, or the title and opening paragraph of a file without one. Steps come in the order
  they are done. A text never contradicts another document.
- **Concise.** Every sentence gives the reader a fact, a rule or a reason they need. Nothing
  is said twice in a file, a linked rule is not restated (Rule placement), and there is no
  filler.
