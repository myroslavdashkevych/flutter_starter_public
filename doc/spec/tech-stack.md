# Tech Stack

**Here:** the approved dependencies with their purpose, the toolchain the starter was last
verified with, compatibility notes (why a version is held back or what an upgrade needs),
deferred and excluded packages.

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

## 3. Verified toolchain

Verified on 2026-11-18: every step of [doc/workflow.md](../workflow.md), Verification, passed
on this Flutter version. The Verification does not build the app, so the Android and iOS
rows are what the repository and the developer's machine set on that date, not a build made
on it. The compatibility notes below and the version-dependent values in
[guide/setup.md](../guide/setup.md) hold for this toolchain.

`.fvmrc` tracks `stable` ([guide/setup.md](../guide/setup.md), FVM), so a newer Flutter may
already be in use; `tool/check_spec.dart` reports it ([doc/workflow.md](../workflow.md),
Requirements). Update the table in the change that runs the Verification on a new
Flutter version or changes a row. Dependabot updates none of these
versions ([guide/setup.md](../guide/setup.md), Dependabot).

| Tool | Version | Set by |
|---|---|---|
| Flutter | 3.50.0 | `.fvmrc` (`stable`) |
| Dart | 3.14.0 | Flutter |
| FVM | 4.3.1 | the developer's machine |
| Gradle | 9.5.0 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 9.3.1 | `android/settings.gradle.kts` |
| Kotlin | 2.4.20 | `android/settings.gradle.kts` |
| Google Services Gradle plugin | 4.4.4 | `android/settings.gradle.kts` |
| Crashlytics Gradle plugin | 3.0.7 | `android/settings.gradle.kts` |
| JDK | 17.0.12 | the developer's machine (`flutter config --jdk-dir`) |
| JVM target | 17 | `android/app/build.gradle.kts` |
| `desugar_jdk_libs` | 2.1.4 | `android/app/build.gradle.kts` |
| Android NDK | 28.2.13676358 | Flutter (`flutter.ndkVersion`) |
| Xcode | 27.2 | the developer's machine |
| iOS Swift packages | resolved versions | `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved` |
| FlutterFire CLI | 1.4.1 | the developer's machine ([guide/setup.md](../guide/setup.md), Firebase) |

Platform levels (`minSdk`, `compileSdk`, `targetSdk`, iOS deployment target):
[guide/setup.md](../guide/setup.md), Platforms.

## 4. Compatibility notes

- **`build_runner` is held back** at 2.16.x (resolved on the verified Flutter version:
  `build_runner` 2.16.1, `freezed` 4.0.3, analyzer 14.1.0). `build_runner` 2.17.1 moved to
  `build` 5, which `injectable_generator` (up to 3.1.3) does not support; 2.17.0 is retracted.
  Revisit when `injectable_generator` is upgraded.
  If `pub get` cannot resolve, stop and report the conflict to the user; do not
  change versions or add overrides without approval.
- **material_ui** replaces `package:flutter/material.dart`, which the verified Flutter version
  reports as deprecated.
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
- **Kotlin Gradle Plugin warning:** the Android build warns that `firebase_analytics`,
  `firebase_auth`, `firebase_core` and `firebase_crashlytics` apply the Kotlin Gradle Plugin.
  Flutter says future versions will fail such builds, and `.fvmrc` tracks `stable`, so this
  can break without a repository change. These plugins are at their latest versions (checked
  on 2026-11-02), so the fix has to come from them. Setting `android.builtInKotlin=true` in
  `android/gradle.properties` was tried and reverted: the warning stayed, and the app crashed
  at startup with `ClassNotFoundException` for `ShareFileProvider` from `share_plus`. The
  cause of that crash is not established.
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

## 5. Deferred

- `google_sign_in` (7.x) together with Sign in with Apple. Apple App Store rules
  require offering Sign in with Apple when Google sign-in is offered on iOS.
- `connectivity_plus`, only if an offline banner is needed.

## 6. Intentionally not included

- **`hive_ce_generator` (^1.12.0):** Hive stores JSON strings produced by DTOs
  ([architecture.md](architecture.md), Local storage), so no type adapters are generated.
  Add it back only with user approval if Hive adapters are ever needed.
