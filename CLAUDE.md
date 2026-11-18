# CLAUDE.md

Project-level guidance. Global `~/.claude/CLAUDE.md` rules (sections 5-7) always apply and are not relaxed here.

**Here:** what applies only to agents: the change workflow additions, tooling, commands and working rules.

**Not here:** the product (`doc/spec/product.md`) and every rule about the code and the process (`doc/`). If this file and `doc/` disagree, stop and ask the user which one is right.

## Project

`flutter_starter`: a GitHub template for small and medium Flutter apps (Android and iOS), built for developers working with AI agents; see `doc/spec/product.md`, Vision.

These documents are imported, so they are always in context:

@doc/workflow.md
@doc/agent-reading.md
@doc/spec/architecture.md
@doc/spec/code-style.md
@doc/spec/security.md

Everything else you read, and when, follows `doc/agent-reading.md`.

## Change workflow

Additions to the change workflow:

- Wait for the user's approval of `change-plan.md` before implementing. Minimal-code rules apply inside the approved plan, not instead of it.
- Run the `change-reviewer` agent only after the user's yes, also for a repeated review after fixes. When a change is ready for review (Verification passed), ask the user whether to run it; in the Claude desktop app, offer a reply button.
- When running the `change-reviewer` agent (`.claude/agents/change-reviewer.md`): pass `change: none` for a change without a folder, pass the optional parameter block, do not override its model or effort, and bring its questions to the user.
- A reviewer report is complete only when it has all five headings of its Report section and its Checklist coverage marks every item of pass 1 (1-8), pass 2 (1-8) and each `extra` item. Otherwise the review is incomplete (for example, the agent ran out of turns or context): tell the user and do not treat the change as reviewed.

## Tooling

- Flutter is managed with FVM (`.fvmrc` tracks the `stable` channel by design, see `doc/guide/setup.md`, FVM; `.fvm/` is gitignored). Always run commands through `fvm`.
- Two flavors: `dev` and `prod`. Every run needs `--flavor` and `--dart-define-from-file`.
- Lints: `package:flutter_lints/flutter.yaml` plus extra rules in `analysis_options.yaml`; generated files are excluded from analysis.
- `.claude/settings.json` is the agent access policy (`doc/spec/security.md`, Agent access) and auto-formats edited `.dart` files via a hook.
- Prefer the Dart/Flutter MCP tools (analyze, hot reload, runtime errors, widget inspector) over ad-hoc shell commands when they are available.

## Commands

```bash
fvm flutter pub get
fvm flutter run --flavor dev --dart-define-from-file=config/dev.json     # the user runs the app
fvm flutter run --flavor prod --dart-define-from-file=config/prod.json   # the user runs the app
fvm flutter analyze
fvm flutter test
fvm flutter test test/path/to/file_test.dart       # single file
fvm flutter test --plain-name "<test name>"        # single test by name
fvm dart run build_runner build                    # code generation
fvm flutter gen-l10n                               # localization code
fvm dart run tool/check_imports.dart               # architecture import rules
fvm dart run tool/check_spec.dart                  # spec conventions and doc links
fvm dart run tool/check_spec.dart --base develop   # also: no requirement ID removed since develop (as in CI)
fvm dart format <changed files>
fvm dart format --output=none --set-exit-if-changed lib test tool   # format check, writes nothing
```

Run each command as its own Bash call, without pipes, `;`, `&&` or redirections: the `allow` list in `.claude/settings.json` must match every part of a compound command, so a combined command asks for permission.

Commands for one procedure (native splash, launcher icons, hosted pages, renaming a new project) are in `doc/guide/setup.md` and `doc/guide/new-project.md`, with who may run them.

## Verification before "done"

Run the steps in `doc/workflow.md`, Verification, before saying "done". Skip `fvm dart format` on files the format hook already handled.

## Architecture

Not decided yet (ask the user and propose options before choosing; do not pick silently):

- Anything not covered by `doc/` (new packages, new screens, new storage)

## Working rules for this project

- The approved dependency set is in `doc/spec/tech-stack.md`. Any `pubspec.yaml` change, including adding an approved package, follows the global rule: say what and why, wait for approval.
- Check package versions in `pubspec.lock` and the package docs before using an API (global rule). freezed 4, go_router 18, firebase_auth 7 and google_sign_in 7 changed APIs recently; many online examples are outdated.
- Commits only when the user asks. Message format: `doc/workflow.md`, Changes.
- Edit repository files (docs, configs, code) only with the Edit and Write tools, not with shell scripts, heredocs or `sed`.
