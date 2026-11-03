# Tech Stack

Approved dependency set. Version constraints live in `pubspec.yaml` and resolved versions
in `pubspec.lock`; versions held back on purpose are explained in section 3.
Any change requires explicit user approval (see `CLAUDE.md`). Which layer may import a
new package is decided in `docs/architecture.md` section 3.

## 1. Runtime dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management |
| `stream_transform` | `debounce` and `switchMap` for BLoC event transformers |
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
| `talker_bloc_logger` | BLoC logging |
| `talker_dio_logger` | HTTP logging |
| `firebase_core` | Firebase |
| `firebase_auth` | Authentication |
| `firebase_crashlytics` | Crash reporting |
| `firebase_analytics` | Analytics |
| `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Foreground notifications on Android |
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
| `bloc_test` | BLoC tests |
| `flutter_native_splash` | Native splash generator, dev-only: it writes platform files once and the app has no runtime dependency on it |
| `flutter_launcher_icons` | Launcher icons per flavor, dev-only: it writes platform files and the app has no runtime dependency on it |

SDK packages: `flutter_test`.

## 3. Compatibility notes

- **Generator versions are held back** to resolve on Flutter 3.47.7 (resolved:
  `freezed` 4.0.1, `build_runner` 2.16.1, analyzer 13.3.0):
  - `freezed` 4.0.2+ requires analyzer 14. Every `package:test` release that
    supports analyzer 14 needs `test_api` 0.7.13+, while the Flutter SDK pins
    `test_api` 0.7.12 through `flutter_test`, so it cannot coexist with `bloc_test`.
  - `build_runner` 2.17.1 moved to `build` 5, which `injectable_generator`
    (up to 3.1.3) does not support; 2.17.0 is retracted.
  - Revisit both when Flutter or `injectable_generator` is upgraded.
  If `pub get` cannot resolve, stop and report the conflict to the user; do not
  change versions or add overrides without approval.
- **freezed 4 breaking change:** no `final` keyword on constructor parameters.
  Classes must be `sealed` or `abstract`.
- **FlutterFire packages** are released together. Upgrade all five at once.
- **Talker packages** share one version. Upgrade them together.
- **bloc line:** `flutter_bloc 9` and `bloc_test 10` both target `bloc 9`.
  `bloc` itself is a transitive dependency.
- **intl** stays `any`; `flutter_localizations` pins it per Flutter SDK.
- **flutter_launcher_icons** 0.14.4 limits `cli_util` to `^0.4.1`, so pub lowered
  `cli_util` (0.6.0 → 0.4.2) and `coverage` (1.16.0 → 1.15.1). Both are dev tooling only.
  If this blocks upgrades of other dev packages, remove it from `pubspec.yaml` and run the
  generator globally (`fvm dart pub global activate flutter_launcher_icons`). The generated
  icons are committed, so a permanent dependency is not needed.
- **flutter_local_notifications** requires Android core library desugaring even
  when scheduled notifications are not used (package README). It is enabled in
  `android/app/build.gradle.kts` (`desugar_jdk_libs` version from the package README).

## 4. Decisions and rejected alternatives

| Area | Choice | Rejected | Reason |
|---|---|---|---|
| State | flutter_bloc | Riverpod, Provider, GetX | Predictable event/state model, strong testing, team experience |
| DI | get_it + injectable | Manual DI, Riverpod DI | Environments, scopes, scales with Clean Architecture |
| Navigation | go_router + builder | auto_route | Maintained by the Flutter team, stable API |
| HTTP | dio + retrofit | http, chopper | Interceptors (auth refresh, logging), declarative clients |
| Models | freezed + json_serializable | dart_mappable, manual | Largest ecosystem, unions, deep copyWith |
| Local DB | hive_ce | drift, isar, objectbox | Search and pagination are server-side; local data is a response cache and per-user favorites read as a whole. Revisit with drift if offline querying is needed |
| Settings | SharedPreferencesAsync | Hive | Few scalar values; async API is isolate-safe |
| Secure storage | none | flutter_secure_storage | Firebase Auth persists and refreshes the session itself |
| Errors | own sealed `Result` | fpdart | Native pattern matching, no FP dependency |
| l10n | gen-l10n | slang, easy_localization | Official, no extra dependency |
| Logging | talker | logger | BLoC/Dio integrations, in-app log screen |
| Mocks | mocktail | mockito | No codegen in tests |
| Lints | flutter_lints + extra rules | very_good_analysis | Less noise, fewer dependencies |
| Images | cached_network_image_ce | cached_network_image | Original is unmaintained; the CE fork uses hive_ce, which is already in the stack |
| Items source | Rick and Morty API | DummyJSON, JSONPlaceholder | Stable, no key, server pagination and search, images |

## 5. Deferred

- `google_sign_in` (7.x) together with Sign in with Apple. Apple App Store rules
  require offering Sign in with Apple when Google sign-in is offered on iOS.
- `connectivity_plus`, only if an offline banner is needed.

## 6. Intentionally not included

- **`hive_ce_generator` (^1.12.0):** Hive stores JSON strings produced by DTOs
  (see `docs/architecture.md` 5.6), so no type adapters are generated. Leaving it
  out means one less generator to keep compatible with analyzer. Add it back only
  with user approval if Hive adapters are ever needed.
