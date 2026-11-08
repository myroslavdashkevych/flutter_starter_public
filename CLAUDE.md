# CLAUDE.md

Project-level guidance. Global `~/.claude/CLAUDE.md` rules (sections 5-7) always apply and are not relaxed here.

## Project

`flutter_starter`: a GitHub template repository for new Flutter apps. Targets: Android and iOS only (no web/desktop). It is a small working demo app (auth, items list and details, profile, settings) that shows the agreed architecture, stack and conventions end to end. Every new project starts as a copy of it, so clarity and consistency matter more than feature count.

Detailed documentation lives in `docs/`; this file adds only what applies to agents. If they disagree, stop and ask the user which one is right.

These documents are imported, so they are always in context:

@docs/README.md
@docs/reading-rules.md
@docs/spec/architecture.md

Everything else you read, and when, follows `docs/reading-rules.md`.

## Change workflow

Additions to the change process:

- Wait for the user's approval of `tasks.md` before implementing. Minimal-code rules apply inside the approved plan, not instead of it.
- When running the `change-reviewer` agent (`.claude/agents/change-reviewer.md`): pass `change: none` for a change without a folder, pass the optional parameter block, do not override its model or effort, and bring its questions to the user.
- A reviewer report is complete only when it has all five headings of its Report section and its Checklist coverage marks every item of pass 1 (1-6), pass 2 (1-8) and each `extra` item. Otherwise the review is incomplete (for example, the agent ran out of turns or context): tell the user and do not treat the change as reviewed.

## Tooling

- Flutter is managed with FVM (`.fvmrc` tracks the `stable` channel by design, see `docs/guides/setup.md`, FVM; `.fvm/` is gitignored). Always run commands through `fvm`.
- Two flavors: `dev` and `prod`. Every run needs `--flavor` and `--dart-define-from-file`.
- Lints: `package:flutter_lints/flutter.yaml` plus extra rules in `analysis_options.yaml`; generated files are excluded from analysis.
- `.claude/settings.json` auto-formats edited `.dart` files via a hook and pre-approves analyze/test/format/codegen/import-check/spec-check commands and `tool/review_diff.dart`; no git command is pre-approved, and git `--output` is denied.
- The `change-reviewer` agent reads git and searches files only through `tool/review_diff.dart` (`files`, `diff`, `log`, `show`, `search`), which never prints never-read files. Other sessions prefer it over raw `git diff`, `git log` and `git show` too: it needs no permission prompt and cannot print the Firebase configs.
- Prefer the Dart/Flutter MCP tools (analyze, hot reload, runtime errors, widget inspector) over ad-hoc shell commands when they are available.
- Run apps on emulators and simulators only; physical devices need the user's approval (global rule).

## Commands

```bash
fvm flutter pub get
fvm flutter run --flavor dev --dart-define-from-file=config/dev.json
fvm flutter run --flavor prod --dart-define-from-file=config/prod.json
fvm flutter analyze
fvm flutter test
fvm flutter test test/path/to/file_test.dart       # single file
fvm flutter test --plain-name "<test name>"        # single test by name
fvm dart run build_runner build                    # code generation (ask before --delete-conflicting-outputs)
fvm flutter gen-l10n                               # localization code
fvm dart run tool/check_imports.dart               # architecture import rules
fvm dart run tool/check_spec.dart                  # spec conventions and doc links
fvm dart run tool/check_spec.dart --base develop   # also: no requirement ID removed since develop (as in CI)
fvm dart format <changed files>
fvm dart format --output=none --set-exit-if-changed lib test tool   # format check, writes nothing
```

Commands for one procedure (native splash, launcher icons, hosted pages, renaming a new project) are in `docs/guides/setup.md` and `docs/guides/new-project.md`, with who may run them.

## Verification before "done"

Run the steps in `docs/README.md`, Verification, before saying "done". Skip `fvm dart format` on files the format hook already handled.

## Architecture

Not decided yet (ask the user and propose options before choosing; do not pick silently):

- Anything not covered by `docs/` (new packages, new screens, new storage)

## Working rules for this project

- The approved dependency set is in `docs/spec/tech-stack.md`. Any `pubspec.yaml` change, including adding an approved package, follows the global rule: say what and why, wait for approval.
- Firebase config files (`google-services.json`, `GoogleService-Info.plist`, `lib/app/firebase/firebase_options_*.dart`) are never read; reference them by path only. The user generates them by running `flutterfire configure`; prepare the exact commands, never run `firebase` or `flutterfire` yourself.
- Check package versions in `pubspec.lock` and the package docs before using an API (global rule). freezed 4, go_router 18, firebase_auth 7 and google_sign_in 7 changed APIs recently; many online examples are outdated.
- Commits only when the user asks. Message format: `docs/README.md`, Changes.
- If a hook blocks a command, stop and tell the user. Do not make the same change another way.
- Edit repository files (docs, configs, code) only with the Edit and Write tools, not with shell scripts, heredocs or `sed`.
