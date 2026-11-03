# CLAUDE.md

Project-level guidance. Global `~/.claude/CLAUDE.md` rules (sections 5-7) always apply and are not relaxed here.

## Project

`flutter_starter`: a GitHub template repository for new Flutter apps. Targets: Android and iOS only (no web/desktop). It is a small working demo app (auth, items list and details, profile, settings) that shows the agreed architecture, stack and conventions end to end. Every new project starts as a copy of it, so clarity and consistency matter more than feature count.

Detailed documentation lives in `docs/`; this file is the short version. If they disagree, stop and ask the user which one is right.

| Document | Read it when |
|---|---|
| `docs/architecture.md` | Before writing or moving any code |
| `docs/tech-stack.md` | Before touching `pubspec.yaml` or using a package API |
| `docs/features.md` | Before implementing or changing app behavior |
| `docs/setup.md` | For FVM, flavors, Firebase, CI, security, splash, icons, hosting |
| `docs/new-project.md` | When turning a copy of the starter into a new app |
| `docs/store-release.md` | Before preparing a store submission |

## Tooling

- Flutter is managed with FVM (`.fvmrc` tracks the `stable` channel by design, see `docs/setup.md` section 2; `.fvm/` is gitignored). Always run commands through `fvm`.
- Two flavors: `dev` and `prod`. Every run needs `--flavor` and `--dart-define-from-file`.
- Lints: `package:flutter_lints/flutter.yaml` plus extra rules in `analysis_options.yaml`; generated files are excluded from analysis.
- Import rules are enforced by `tool/check_imports.dart` (also in CI).
- `.claude/settings.json` auto-formats edited `.dart` files via a hook and pre-approves analyze/test/format/codegen/import-check commands.
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
fvm dart run flutter_native_splash:create          # native splash, after changing flutter_native_splash.yaml
fvm dart run flutter_launcher_icons                # launcher icons per flavor, after changing assets/icons or flutter_launcher_icons-*.yaml
firebase deploy --only hosting --project prod      # hosted pages: run by the user, never by the agent
fvm dart run tool/check_imports.dart               # architecture import rules
fvm dart run tool/init_project.dart --name "My App" --package my_app --org com.example --firebase-prefix my-app-demo --dry-run   # rename for a new project: project-wide, run only when the user asks (docs/new-project.md section 2)
fvm dart format <changed files>
fvm dart format --output=none --set-exit-if-changed lib test tool   # format check, writes nothing
```

## Verification before "done"

1. If annotated classes or ARB files changed: `fvm dart run build_runner build` / `fvm flutter gen-l10n`
2. `fvm flutter analyze` (no issues)
3. `fvm dart run tool/check_imports.dart`
4. `fvm flutter test`
5. `fvm dart format` on changed files only (skip files the format hook already handled)
6. New user-facing strings exist in both `app_en.arb` and `app_uk.arb`
7. `docs/` updated if behavior, structure or dependencies changed (ask first if the change is to `CLAUDE.md`)

## Architecture

Decided (details and rationale in `docs/architecture.md` and `docs/tech-stack.md`):

- **Structure:** Clean Architecture layers at the top level, business areas and user flows inside them:
  - `lib/app/`: composition root (DI, router, bootstrap, flavor config, Firebase options). The only module that knows everything.
  - `lib/shared/`: cross-layer code only (logging, pure utilities). Imports no layer.
  - `lib/domain/<area>/`: pure Dart entities, abstract repositories, use cases. No Flutter, dio, hive or firebase.
  - `lib/data/<area>/`: data sources, DTOs, mappers, repository implementations.
  - `lib/presentation/<feature>/`: pages, widgets, BLoCs/Cubits. Never imports `data` or another feature.
  - `<layer>/_shared/`: code shared inside one layer; it obeys that layer's rules. `shared` and `_shared` are reserved names.
- **State management:** `flutter_bloc` (Cubit by default; Bloc when event transformers such as debounce or restartable are needed). States are freezed classes. No `BuildContext` in BLoCs.
- **Use cases:** optional. Add one when there is real logic (several repositories, validation, business rules); otherwise a BLoC calls the repository directly. Use cases live in `domain/<area>/usecases`; a use case may depend on repository contracts of other areas.
- **Dependency injection:** `get_it` + `injectable`. `getIt<T>()` is called only in `app/` (route builders create BLoCs there); everything else uses constructor injection.
- **Navigation:** `go_router` + `go_router_builder`. The typed route tree lives in `app/router/routes.dart`. Features never navigate by themselves: pages take navigation callbacks, route builders implement them. Pass ids, never whole domain objects.
- **Networking:** `dio` + `retrofit`. `publicDio` (no auth) for third-party APIs, `backendDio` with `AuthInterceptor` for the own backend. Never send the Firebase ID token to a third-party API.
- **Models:** entities are freezed without JSON (domain); DTOs are freezed + `json_serializable` (data); mappers live in data. freezed 4: classes are `sealed` or `abstract`, no `final` on constructor parameters.
- **Errors:** repositories return `Result<T>` (`Ok` / `Err` with a sealed `Failure`) and never throw. Exceptions are converted in `data` only; failures become user messages in `presentation/_shared/l10n` only. Never swallow errors silently.
- **Local persistence:** settings in `SharedPreferencesAsync`; API cache in hive_ce `LazyBox` as JSON strings from DTOs (no Hive adapters); favorites in per-user hive_ce `LazyBox` (`favorites_<uid in hex>`), persistent, not a cache. Local data is either a cache or user data: caches implement `ExpiringCache` and expire (items: 90 days); user data (favorites) is never deleted automatically, only by a user action. Unsure which: treat it as user data (`docs/architecture.md` section 5.6). Nothing outside `data` knows about storage. No Hive access from the FCM background isolate.
- **Localization:** gen-l10n, `en` (template) and `uk`, generated into `lib/l10n/gen`. `domain` and `data` never produce user-facing text.
- **Firebase:** Auth (email/password), Crashlytics, Analytics, Messaging. Each flavor has its own Firebase project.

Not decided yet (ask the user and propose options before choosing; do not pick silently):

- Anything not covered by `docs/` (new packages, new screens, new storage)

## Working rules for this project

- The approved dependency set is in `docs/tech-stack.md`. Any `pubspec.yaml` change, including adding an approved package, follows the global rule: say what and why, wait for approval.
- A new package belongs to `data` or `presentation` by default, and the other layer must not import it. If both really need it, add it to `_sharedPackages` in `tool/check_imports.dart` (`docs/architecture.md` section 3, "External packages").
- Firebase config files (`google-services.json`, `GoogleService-Info.plist`, `lib/app/firebase/firebase_options_*.dart`) are never read; reference them by path only. The user generates them by running `flutterfire configure`; prepare the exact commands, never run `firebase` or `flutterfire` yourself.
- For a new feature or module: propose a short plan first (areas, screens, states, data flow, tests), get approval, then implement. Minimal-code rules apply inside the approved plan, not instead of it.
- Check package versions in `pubspec.lock` and the package docs before using an API (global rule). freezed 4, go_router 18, firebase_auth 7 and google_sign_in 7 changed APIs recently; many online examples are outdated.
- Commits only when the user asks. Conventional Commits in English: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `ci:`.
- If a hook blocks a command, stop and tell the user. Do not make the same change another way.
- Edit repository files (docs, configs, code) only with the Edit and Write tools, not with shell scripts, heredocs or `sed`.

## Testing

- Mirror `lib/` under `test/`; shared mocks and `registerFallbackValue` setup live in `test/helpers/`.
- BLoCs/Cubits: `bloc_test` + `mocktail`; cover each state transition.
- Repositories, use cases, interceptors, mappers: plain unit tests with `mocktail` (Dio with a mocked adapter).
- `tool/check_imports.dart`: unit tests for every rule.
- `tool/init_project.dart`: unit tests for the renames on fixtures and for argument validation.
- UI: widget tests for critical flows (sign-in validation, list states); for animations and platform behavior describe a manual check.
- Firebase is never called in tests; it sits behind repositories and ports.
