# Tech Stack

**Here:** the approved dependencies with their purpose, compatibility notes (why a version is
held back or what an upgrade needs), deferred and excluded packages.

**Not here:** version constraints (`pubspec.yaml`) and resolved versions (`pubspec.lock`); how
a dependency change is approved (`CLAUDE.md`, Working rules for this project); which layer may
import a package ([architecture.md](architecture.md), External packages).

## 1. Runtime dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management |
| `bloc_concurrency` | Event transformers: `sequential`, `droppable`, `restartable`, `concurrent` |
| `stream_transform` | `debounce` and `switchMap` for the search event transformer; `switchMap` and `startWith` in domain use cases that follow the current user |
| `get_it` | Service locator / DI container |
| `injectable` | DI annotations |
| `go_router` | Navigation, redirects, in-app routes from notifications |
| `dio` | HTTP client |
| `retrofit` | Declarative API clients on top of Dio |
| `freezed_annotation` | Immutable models and unions |
| `json_annotation` | JSON annotations |
| `hive_ce` | Local API response cache and favorites |
| `hive_ce_flutter` | Hive Flutter integration |
| `shared_preferences` | Settings (`SharedPreferencesAsync`) |
| `intl` | Constraint `any`: pinned by `flutter_localizations` |
| `talker` | Logging and error handling |
| `talker_flutter` | `TalkerScreen`, Flutter integration |
| `talker_bloc_logger` | Bloc logging |
| `talker_dio_logger` | HTTP logging |
| `firebase_core` | Firebase |
| `firebase_auth` | Authentication |
| `firebase_crashlytics` | Crash reporting |
| `firebase_analytics` | Analytics |
| `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Foreground notifications on Android |
| `material_ui` | Material widgets, theme and Material localizations, moved out of the Flutter SDK |
| `cached_network_image_ce` | Cached network images (Hive-backed) |
| `package_info_plus` | App version on the settings page |
| `url_launcher` | Opens the privacy policy in the in-app browser |

SDK packages: `flutter`, `flutter_localizations`.

`cupertino_icons` from the Flutter project template is removed: the app uses Material
`Icons` only. Add it back if a project needs `CupertinoIcons`.

## 2. Dev dependencies

| Package | Purpose |
|---|---|
| `flutter_lints` | Base lint set (extended in `analysis_options.yaml`) |
| `build_runner` | Code generation runner |
| `freezed` | Generator for freezed |
| `json_serializable` | JSON generator |
| `injectable_generator` | DI generator |
| `retrofit_generator` | API client generator |
| `go_router_builder` | Typed routes generator |
| `mocktail` | Mocks without codegen |
| `bloc_test` | Bloc tests |
| `flutter_native_splash` | Native splash generator, dev-only: it writes platform files once and the app has no runtime dependency on it |
| `flutter_launcher_icons` | Launcher icons per flavor, dev-only: it writes platform files and the app has no runtime dependency on it |

SDK packages: `flutter_test`.

## 3. Compatibility notes

- **`build_runner` is held back** at 2.16.x (resolved on Flutter 3.50.0: `build_runner`
  2.16.1, `freezed` 4.0.3, analyzer 14.1.0). `build_runner` 2.17.1 moved to `build` 5,
  which `injectable_generator` (up to 3.1.3) does not support; 2.17.0 is retracted.
  Revisit when `injectable_generator` is upgraded.
  If `pub get` cannot resolve, stop and report the conflict to the user; do not
  change versions or add overrides without approval.
- **material_ui** replaces `package:flutter/material.dart`, which Flutter 3.50 reports as
  deprecated.
  Every `MaterialApp`, in the app and in tests, takes `appLocalizationsDelegates`
  (`presentation/_shared/l10n`): the translations of both libraries, because
  `material_ui` widgets do not read those of the legacy one. `talker_flutter`
  (`TalkerScreen`) still builds legacy widgets, so it keeps the legacy translations and
  the legacy default theme; `cached_network_image_ce` and `hive_ce_flutter` only import
  the legacy library. `MaterialUiCompatibilityBridge` is not used: it is deprecated itself.
  Drop the legacy translations from `appLocalizationsDelegates` when `talker_flutter` has
  migrated.
- **freezed 4 breaking change:** the class rules are in
  [architecture.md](architecture.md), Entities and DTOs.
- **FlutterFire packages** are released together. Upgrade all five at once.
- **Talker packages** share one version. Upgrade them together.
- **bloc line:** `flutter_bloc 9`, `bloc_test 10` and `bloc_concurrency 0.3` all target
  `bloc 9`. `bloc` itself is a transitive dependency. Upgrade them together.
- **intl** stays `any`; `flutter_localizations` pins it per Flutter SDK.
- **flutter_launcher_icons** 0.14.4 limits `cli_util` to `^0.4.1`, so pub lowered
  `cli_util` (0.6.0 → 0.4.2) and `coverage` (1.16.0 → 1.15.1). Both are dev tooling only.
  If this blocks upgrades of other dev packages, remove it from `pubspec.yaml` and run the
  generator globally (`fvm dart pub global activate flutter_launcher_icons`). The generated
  icons are committed, so a permanent dependency is not needed.
- **flutter_local_notifications** requires Android core library desugaring even
  when scheduled notifications are not used (package README). It is enabled in
  `android/app/build.gradle.kts` (`desugar_jdk_libs` version from the package README).

## 4. Deferred

- `google_sign_in` (7.x) together with Sign in with Apple. Apple App Store rules
  require offering Sign in with Apple when Google sign-in is offered on iOS.
- `connectivity_plus`, only if an offline banner is needed.

## 5. Intentionally not included

- **`hive_ce_generator` (^1.12.0):** Hive stores JSON strings produced by DTOs
  ([architecture.md](architecture.md), Local storage), so no type adapters are generated.
  Add it back only with user approval if Hive adapters are ever needed.
