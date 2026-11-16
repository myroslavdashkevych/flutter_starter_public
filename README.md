# Flutter Starter

A production-ready template for Flutter mobile apps (Android and iOS).
It is a small working app that demonstrates the architecture, stack and
conventions every new project starts from.

## What the demo app does

- Optional email/password authentication with Firebase Auth (sign in, sign up, password reset).
- Bottom navigation with three tabs: Characters, Profile, Settings.
- Characters: a paginated, searchable list from the public
  [Rick and Morty API](https://rickandmortyapi.com/documentation), cached locally.
- Character details screen.
- Profile: sign-in entry for guests; account info, favorites, sign out, account deletion when
  signed in.
- Settings: theme (system / light / dark), language (system / English / Ukrainian),
  a "Share usage data" switch and the privacy policy.
- Crashlytics, Analytics and push notifications (Android; iOS needs an APNs key).
- Two flavors: `dev` and `prod`, each with its own Firebase project.

## Stack at a glance

flutter_bloc (Bloc only) · get_it + injectable · go_router + go_router_builder · dio + retrofit ·
freezed + json_serializable · hive_ce · shared_preferences · gen-l10n ·
talker · FlutterFire · mocktail + bloc_test.

Full list and compatibility notes: [doc/spec/tech-stack.md](doc/spec/tech-stack.md);
rationale: [doc/decision/](doc/decision/).

## Requirements

- [FVM](https://fvm.app). `.fvmrc` tracks the Flutter `stable` channel.
- Xcode (iOS) and Android Studio / Android SDK (Android).
- Firebase CLI and FlutterFire CLI, only to (re)configure Firebase.

## Quick start

```bash
fvm install
fvm flutter pub get
fvm dart run build_runner build
fvm flutter gen-l10n
fvm flutter run --flavor dev --dart-define-from-file=config/dev.json
```

The repository ships without Firebase configs, so `flutter run` works only after you
connect your own Firebase projects
([doc/guide/new-project.md](doc/guide/new-project.md#3-connect-your-own-firebase-projects),
Connect your own Firebase projects).
Analyze and the tests work without them.

## Project structure

```
lib/
  main.dart
  app/        # composition root: DI, router, bootstrap, Firebase options
  shared/     # cross-layer: logging, pure utilities
  domain/     # pure Dart: entities, repository contracts, use cases
  data/       # repository implementations, data sources, DTOs
  presentation/  # UI: pages, widgets, Blocs
  l10n/       # ARB files and generated localizations
```

Details and import rules: [doc/spec/architecture.md](doc/spec/architecture.md).

## Starting a new project from this template

Follow [doc/guide/new-project.md](doc/guide/new-project.md): create a repository from this
template, rename it with `tool/init_project.dart`, connect your own Firebase projects, replace
the starter's content and spec, remove the demo blocks and any optional block you do not need
([Demo and optional blocks](doc/guide/new-project.md#5-demo-and-optional-blocks)), then release.

## Documentation

New here? Start with [doc/guide/onboarding.md](doc/guide/onboarding.md).

| Document | Contents |
|---|---|
| [doc/guide/onboarding.md](doc/guide/onboarding.md) | Finding your way around: the mental model, one request through the code, reading order |
| [CLAUDE.md](CLAUDE.md) | Project rules for AI coding agents (with `.claude/settings.json`) |
| [doc/README.md](doc/README.md) | Documentation map and conventions: source of truth, requirement IDs, change process |
| [doc/reading-rule.md](doc/reading-rule.md) | Reading rules for agents: what to read for which change |
| [doc/spec/](doc/spec/) | Living specification: product, behavior, areas, architecture, code style, security, tech stack |
| [doc/decision/](doc/decision/) | Architecture decision records |
| [doc/design/](doc/design/README.md) | Design conventions and approved screens |
| [doc/guide/setup.md](doc/guide/setup.md) | FVM, flavors, Firebase, CI, security, splash, icons, hosting |
| [doc/guide/new-project.md](doc/guide/new-project.md) | Turning a copy of the starter into a new app |
| [doc/guide/store-release.md](doc/guide/store-release.md) | Submission checklist, store data declarations |

## Known limitations

- iOS push notifications require an APNs key from a paid Apple Developer
  Program membership. Without it, everything else works on iOS.
- Google Sign-In and Sign in with Apple are intentionally not included yet.
- A project created with `tool/init_project.dart` has not yet been built with configs from
  new Firebase projects; the first real project closes this check. What was verified:
  [doc/guide/new-project.md](doc/guide/new-project.md#7-what-has-been-verified).
- The Android build warns that `firebase_analytics`, `firebase_auth`, `firebase_core` and
  `firebase_crashlytics` apply the Kotlin Gradle Plugin. Flutter says future versions will
  fail such builds, and `.fvmrc` tracks `stable`, so this can break without a repository
  change. These plugins are at their latest versions (checked on 2026-11-02), so the fix has
  to come from them. Setting `android.builtInKotlin=true` in `android/gradle.properties` was
  tried and reverted: the warning stayed, and the app crashed at startup with
  `ClassNotFoundException` for `ShareFileProvider` from `share_plus`. The cause of that crash
  is not established.

## License

[MIT](LICENSE)
