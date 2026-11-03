# Flutter Starter

A production-ready template for Flutter mobile apps (Android and iOS).
It is a small working app that demonstrates the architecture, stack and
conventions every new project starts from.

## What the demo app does

- Optional email/password authentication with Firebase Auth (sign in, sign up, password reset).
- Bottom navigation with three tabs: Items, Profile, Settings.
- Items: a paginated, searchable list from the public
  [Rick and Morty API](https://rickandmortyapi.com/documentation), cached locally.
- Item details screen.
- Profile: sign-in entry for guests; account info, favorites, sign out, account deletion when
  signed in.
- Settings: theme (system / light / dark), language (system / English / Ukrainian),
  a "Share usage data" switch and the privacy policy.
- Crashlytics, Analytics and push notifications (Android; iOS needs an APNs key).
- Two flavors: `dev` and `prod`, each with its own Firebase project.

## Stack at a glance

BLoC · get_it + injectable · go_router + go_router_builder · dio + retrofit ·
freezed + json_serializable · hive_ce · shared_preferences · gen-l10n ·
talker · FlutterFire · mocktail + bloc_test.

Full list with versions and rationale: [docs/tech-stack.md](docs/tech-stack.md).

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
([docs/new-project.md section 3](docs/new-project.md#3-connect-your-own-firebase-projects)).
Analyze and the tests work without them.

## Project structure

```
lib/
  main.dart
  app/        # composition root: DI, router, bootstrap, Firebase options
  shared/     # cross-layer: logging, pure utilities
  domain/     # pure Dart: entities, repository contracts, use cases
  data/       # repository implementations, data sources, DTOs
  presentation/  # UI: pages, widgets, BLoCs
  l10n/       # ARB files and generated localizations
```

Details and import rules: [docs/architecture.md](docs/architecture.md).

## Starting a new project from this template

Follow [docs/new-project.md](docs/new-project.md): create a repository from this template,
rename it with `tool/init_project.dart`, connect your own Firebase projects, replace the
starter's content, remove the demo blocks and any optional block you do not need
([section 5](docs/new-project.md#5-demo-and-optional-blocks)), then release.

## Documentation

| Document | Contents |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Project rules for AI coding agents (with `.claude/settings.json`) |
| [docs/architecture.md](docs/architecture.md) | Layers, folders, import rules, patterns |
| [docs/tech-stack.md](docs/tech-stack.md) | Dependencies, compatibility, decisions |
| [docs/features.md](docs/features.md) | Functional specification of the demo app |
| [docs/setup.md](docs/setup.md) | FVM, flavors, Firebase, CI, security, splash, icons, hosting |
| [docs/new-project.md](docs/new-project.md) | Turning a copy of the starter into a new app |
| [docs/store-release.md](docs/store-release.md) | Submission checklist, store data declarations |

## Known limitations

- iOS push notifications require an APNs key from a paid Apple Developer
  Program membership. Without it, everything else works on iOS.
- Google Sign-In and Sign in with Apple are intentionally not included yet.
- A project created with `tool/init_project.dart` has not yet been built with configs from
  new Firebase projects; the first real project closes this check. What was verified:
  [docs/new-project.md](docs/new-project.md#7-what-has-been-verified).
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
