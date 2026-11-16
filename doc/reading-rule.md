# Reading rules for agents

**Here:** the only list of what an agent reads beyond the documents `CLAUDE.md` imports
(`doc/README.md`, this file, `spec/architecture.md`, `spec/code-style.md` and
`spec/security.md`). It applies to every task that changes files.

**Not here:** what each document holds ([README.md](README.md), Map); the rules themselves.

**When.** Apply the rules before the first edit, to the list of files you plan to change.
When the work reaches a file not on that list, apply them to that file before editing it.

**Section** means a heading and everything under it up to the next heading of the same or a
higher level. A section named here is the heading with exactly that text, optionally
preceded by a number and followed by a part in parentheses: "Change reviewer" is "Change
reviewer (Claude Code)", "Compatibility notes" is "3. Compatibility notes".

**1. Current change.**

- The folder of the current change in `change/`, if it has one. Never the folders of other
  changes, unless the task edits a file in them.

**2. By changed file.** Every row that matches a file you change adds its documents; one
file can match several rows. Paths are relative to the repository root; `setup.md` means
`guide/setup.md`.

Code:

| The change touches | Read |
|---|---|
| a file or folder that the **Areas:** line of a `spec/area/<area>.md` names (its paths are relative to `lib/`) | that file, and the behavior file its **Behavior:** link names. A folder that no **Areas:** line names has no area file; `spec/architecture.md` covers it. |
| `*_page.dart`, `lib/app/router/**` | `spec/behavior/navigation.md` |
| `lib/app/observability/**`, `lib/shared/logging/**`, `lib/data/_shared/service/**`, `lib/domain/_shared/service/**`, or a file that adds a Talker or `CrashReportingService` call | `spec/behavior/observability.md` |
| any file in `lib/presentation/` except `*_bloc.dart`, `*_state.dart`, `*_event.dart` and `lib/presentation/_shared/l10n/**` | `design/README.md`, `spec/behavior/accessibility.md` |
| a new folder directly under `lib/data/` or `lib/presentation/`, or a new contract in `lib/domain/repository/` | `spec/product.md` |
| a new screen (`SCR-n`) or a new requirement prefix | `spec/product.md` |

Packages:

| The change touches | Read |
|---|---|
| `pubspec.yaml`, or an import of a package that no file in `lib/` imported before | `spec/tech-stack.md` |
| a file that gets a new `package:` import (other than `flutter_starter`, `flutter` and `flutter_test`) | `spec/tech-stack.md`: Compatibility notes |

Project setup:

| The change touches | Read |
|---|---|
| `.fvmrc` | `setup.md`: FVM |
| `android/**`, `ios/**` | `setup.md`: Platforms; Flavors |
| `android/app/build.gradle.kts`, `ios/Runner.xcodeproj/**` | `setup.md`: Identifiers; Platforms; Flavors |
| `config/**`, `lib/app/config/**` | `setup.md`: Flavors |
| `lib/app/config/firebase/**`, `lib/main.dart`, `lib/app/bootstrap.dart` | `setup.md`: Firebase |
| `.gitignore`, `android/key.properties` | `setup.md`: Security checklist |
| `build.yaml` | `setup.md`: Generated code |
| `analysis_options.yaml` | `setup.md`: Lints |
| `.github/**` | `setup.md`: CI (GitHub Actions) |
| `flutter_native_splash.yaml`, `assets/splash/**` | `setup.md`: Native splash; `spec/behavior/splash.md` |
| `flutter_launcher_icons-*.yaml`, `assets/icons/**` | `setup.md`: Launcher icons |
| `hosting/**`, `firebase.json`, `.firebaserc` | `setup.md`: Hosted pages |
| `ios/Runner/PrivacyInfo.xcprivacy` | `setup.md`: iOS privacy manifest |
| `.claude/**`, `tool/review_diff.dart` | `setup.md`: Change reviewer |
| a file in `doc/` | that file, whole |

**3. By task.**

- The task names a requirement or screen ID: the behavior file of its prefix (`NAV`
  navigation, `AUTH` auth, `CHR` character, `PRF` profile, `SET` settings, `NTF` notification,
  `OBS` observability, `SPL` splash, `FAV` favorite, `ACC` accessibility; `SCR-n` is defined
  in one of them).
- The change adds, modifies or removes a requirement: the behavior file that holds it.
- A spec line you read links an ADR, and the change touches what that line describes: that
  ADR.
- The task changes a decision an ADR records: that ADR; file names name the decision
  (`decision/ADR-001-<slug>.md`).
- The task turns a copy of the starter into a new app: `guide/new-project.md`.
- The task prepares a store submission: `guide/store-release.md`.

**4. Links.** In a document read under 1-3 or imported by `CLAUDE.md`, follow a link only
when the task needs the fact it points to.

**5. Unsure** whether a row or a section applies: read it. One section too many costs less
than a broken rule.

**6. Not read** unless the user asks: git history, old pull requests, folders of other
changes, and documents that no rule above names.
