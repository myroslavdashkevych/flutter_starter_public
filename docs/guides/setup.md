# Setup

## Identifiers

| | dev | prod |
|---|---|---|
| Dart package (`pubspec` name) | `flutter_starter` | `flutter_starter` |
| Android applicationId / iOS bundle ID | `com.yourcompany.flutterstarter.dev` | `com.yourcompany.flutterstarter` |
| App name on device | `Flutter Starter Dev` | `Flutter Starter` |
| Firebase project ID | `your-firebase-project-dev` | `your-firebase-project` |
| Firebase display name | `Flutter Starter Dev` | `Flutter Starter` |

Organization (reverse domain): `com.yourcompany`.

Firebase project ID convention: `<prefix>-dev` for dev and `<prefix>` without a suffix
for prod. The prod ID is user-facing: by default it forms the auth domain
`<project-id>.firebaseapp.com` used in password reset and email action links.

## FVM

- `.fvmrc` tracks the `stable` channel (`"flutter": "stable"`), not a fixed
  release. This is a deliberate choice: the starter always uses the current
  stable Flutter (3.47.7 at creation time). The trade-off: CI and fresh clones pick
  up a new stable release as soon as it ships, so a Flutter release can break the
  build without any change in the repository. A project created from the template
  may pin an exact version instead (`fvm use <version>`).
  [ADR-012](../decisions/ADR-012-repo-and-toolchain-policy.md).
- All commands use `fvm flutter` / `fvm dart`.
- To upgrade Flutter: change `.fvmrc`, run `fvm install`, then the full
  every step of [docs/README.md](../README.md), Verification. Changing the FVM setup needs the user's
  approval (global rule).

## Platforms

Android and iOS only. Web, macOS, Windows and Linux folders are not created.

- Android `minSdk`: `flutter.minSdkVersion` in `android/app/build.gradle.kts`, which is
  24 on Flutter 3.47.7. It is not pinned, so it follows the Flutter version from `.fvmrc`.
- iOS deployment target: 15.0, set in `ios/Runner.xcodeproj/project.pbxproj` for all six
  build configurations.
- Android `compileSdk` and `targetSdk`: 36, set explicitly in
  `android/app/build.gradle.kts`.

## Flavors

| | dev | prod |
|---|---|---|
| Android product flavor | `dev` (`applicationIdSuffix ".dev"`) | `prod` |
| iOS build configurations | `Debug-dev`, `Profile-dev`, `Release-dev` | `Debug-prod`, `Profile-prod`, `Release-prod` |
| iOS scheme | `dev` | `prod` |
| Runtime config | `config/dev.json` | `config/prod.json` |
| Firebase options | `lib/app/firebase/firebase_options_dev.dart` | `lib/app/firebase/firebase_options_prod.dart` |
| Android Firebase file | `android/app/src/dev/google-services.json` | `android/app/src/prod/google-services.json` |
| iOS Firebase file | `ios/flavors/dev/GoogleService-Info.plist` | `ios/flavors/prod/GoogleService-Info.plist` |

- One `main.dart`. The flavor is read from `appFlavor`
  (`package:flutter/services.dart`) only in `app/bootstrap.dart` and mapped to a
  `Flavor` enum in `app/config/flavor.dart`. A missing or unknown value fails at
  startup. `App` receives `AppConfig` through its constructor, so tests do not
  depend on `appFlavor` (it is null in `flutter test`).
- iOS has only the six configurations above and the `dev` and `prod` schemes; the
  default `Debug`, `Profile`, `Release` and the `Runner` scheme are removed, so
  running without `--flavor` does not work on either platform.
- iOS plugins use Swift Package Manager, so there is no `ios/Podfile`. If one is
  ever added, its `project 'Runner'` mapping must cover all six configurations:
  `Debug-*` → `:debug`, `Profile-*` and `Release-*` → `:release`.
- `config/*.json` holds non-secret values only, because they can be extracted from the
  binary: API base URLs, the items cache TTL, the privacy policy URL and the default of
  the "Share usage data" setting. `AppConfig` reads them.
- Every run needs `--flavor` and `--dart-define-from-file`; the commands are in
  `README.md` (Quick start) and `CLAUDE.md` (Commands).
- Android Studio: the `dev` and `prod` run configurations are committed in `.run/`
  and appear in the run configuration list. Point Settings → Languages & Frameworks
  → Flutter → Flutter SDK path to the project's `.fvm/flutter_sdk`, so the IDE uses
  the same Flutter as `fvm flutter`; this setting lives in the gitignored `.idea/`.

## Firebase

### Done by the user (needs a Google account)

1. Create two projects in Firebase Console with the IDs from "Identifiers".
   Plan: Spark (free).
2. In both projects: **Authentication → Sign-in method → Email/Password → Enable**.
3. Google Analytics: enable when creating each project.
4. Install the Firebase CLI and FlutterFire CLI, then run `firebase login`.

### Generate configs (run by the user)

The agent prepares these commands and the user runs them in their own terminal.
The agent cannot run them: they need the user's Google login, and the global
Claude Code hook blocks any command that mentions `google-services.json` or
`GoogleService-Info.plist`. Check flags against `flutterfire configure --help` of
the installed version before running.

```bash
# dev: run once per iOS build configuration (Debug-dev, Profile-dev, Release-dev)
flutterfire configure \
  --yes \
  --project=your-firebase-project-dev \
  --platforms=android,ios \
  --out=lib/app/firebase/firebase_options_dev.dart \
  --android-package-name=com.yourcompany.flutterstarter.dev \
  --android-out=android/app/src/dev/google-services.json \
  --ios-bundle-id=com.yourcompany.flutterstarter.dev \
  --ios-build-config=Debug-dev \
  --ios-out=ios/flavors/dev/GoogleService-Info.plist

# prod: same, with prod values (Debug-prod, Profile-prod, Release-prod)
flutterfire configure \
  --yes \
  --project=your-firebase-project \
  --platforms=android,ios \
  --out=lib/app/firebase/firebase_options_prod.dart \
  --android-package-name=com.yourcompany.flutterstarter \
  --android-out=android/app/src/prod/google-services.json \
  --ios-bundle-id=com.yourcompany.flutterstarter \
  --ios-build-config=Debug-prod \
  --ios-out=ios/flavors/prod/GoogleService-Info.plist
```

Checked against FlutterFire CLI 1.4.1. `--yes` lets repeated runs overwrite the
Dart options file without a prompt. Besides the config files, the command adds the
Google Services and Crashlytics plugins to the Gradle files, adds two build phases
to the `Runner` target and writes `firebase.json` in the project root. Those build
phases call `flutterfire` and read `firebase.json`, so every iOS build needs the
FlutterFire CLI installed.

### Services per platform

| Service | Android | iOS |
|---|---|---|
| Auth (email/password) | Yes | Yes |
| Crashlytics | Yes | Yes |
| Analytics | Yes | Yes |
| Push (FCM) | Yes | Code present; needs an APNs key (Apple Developer Program), not configured |

### Committing Firebase configs

- The starter ships **without** Firebase configs. `lib/app/firebase/firebase_options_*.dart`
  are placeholders that throw at startup; the Android and iOS config files and the
  `flutter` section of `firebase.json` are missing. Analyze, the import check and the
  tests do not need them, so CI works. `flutterfire configure` (Generate configs) writes
  them.
- A project created from the template commits its configs, so the app runs after
  cloning. They are not secrets; protection relies on Security Rules and on restricted
  API keys.
- Restrict the Firebase API keys in Google Cloud Console (Android: package name +
  SHA-1; iOS: bundle ID).

### Checking Crashlytics and Analytics

- **Crashlytics on iOS debug builds:** `Debug-*` configurations use
  `DEBUG_INFORMATION_FORMAT = dwarf`, so no dSYM exists and the console lists reports
  from them as unprocessed. Check reports on Android, where no dSYM is needed.
- **Test crash:** the dev Settings entry throws a Dart error. The app stays open, and
  on Android the report was uploaded without a restart.
- **DebugView on Android:**
  `adb shell setprop debug.firebase.analytics.app <application id>`, then restart the
  app. The "Debug Device" counter may stay at 0 while events arrive.
- **DebugView on iOS:** the `dev` scheme passes `-FIRDebugEnabled`, which applies only
  when running from Xcode: `flutter run` launches the simulator app without scheme
  arguments. Without Xcode, use
  `xcrun simctl launch booted <bundle id> -FIRDebugEnabled`.

## Security checklist

`.gitignore` excludes secrets from the first commit: `.env` files, keystores,
`key.properties`, service-account JSON files and the Firebase CLI deploy cache. Add a
pattern there before a new kind of secret enters the project.

- No real secrets are ever committed: git history keeps them forever.
- Release signing configs are read from `android/key.properties`, which is not committed.
  When it does not exist, release builds use the debug key, so they cannot be published.
  Format: [store-release.md](store-release.md), Android.
- Network logging and where the Firebase ID token may go:
  [spec/architecture.md](../spec/architecture.md), Networking.

## Generated code

- Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`, `lib/l10n/gen/`)
  are **not committed**. They are listed in `.gitignore` and produced by
  `build_runner` and gen-l10n locally and in CI
  ([ADR-012](../decisions/ADR-012-repo-and-toolchain-policy.md)). The cost: after a fresh clone, run
  `fvm dart run build_runner build` and `fvm flutter gen-l10n` before the app compiles.
- `build.yaml` limits each generator with `generate_for` to the folders that use it.
  When a generator is needed in a new folder, add the folder there first.

## Lints

`analysis_options.yaml` extends `package:flutter_lints/flutter.yaml` with the strict
`strict-casts`, `strict-inference` and `strict-raw-types` modes and a few extra lint
rules. Generated files are excluded from analysis. `build/**`, `android/**` and `ios/**`
are added by the Flutter tool itself when it runs `flutter analyze`, so they are kept
there.

## CI (GitHub Actions)

`.github/workflows/ci.yml` runs on every pull request and on pushes to `main` and
`develop`. It installs the Flutter version from `.fvmrc` with `subosito/flutter-action`,
which reads that file directly, generates code and localizations, and then runs the
checks of [docs/README.md](../README.md), Verification: the format check, analyze, the
import rules ([spec/architecture.md](../spec/architecture.md), Import rules), the spec
conventions (`tool/check_spec.dart`, [docs/README.md](../README.md), Requirements) and the
tests. A fresh checkout has no generated files, so `build_runner` needs no
`--delete-conflicting-outputs`.

The spec check runs with `--base`: the target branch (`origin/<base_ref>`) on a pull request,
the previous tip (`github.event.before`) on a push, and no base on a branch's first push. It
fails when a requirement or screen ID of the base disappeared without being retired
([ADR-015](../decisions/ADR-015-removed-id-check.md)). For this the checkout uses
`fetch-depth: 0`; a shallow clone has no base revision, and the step would exit 2.

The last step warns, once per folder, while `docs/changes/` holds anything besides
`_template`. A change may land in several pull requests, so its folder stays in `develop` until
the last one deletes it ([docs/README.md](../README.md), Changes). The warning keeps a
forgotten folder visible and never fails the job.

The runner may call `flutter`/`dart` directly: the FVM-only rule applies to work
on developer machines, and the runner installs exactly the version from `.fvmrc`.

Safety settings in the workflow; keep them when you change it:

- `permissions: contents: read`: the run's token can only read the repository.
- `persist-credentials: false` on checkout: the token is not left in `.git/config`, so
  later steps (third-party actions, package build hooks, code generators) cannot read
  it. The workflow never pushes, so it needs no stored token.
- `concurrency`: a new push to a pull request cancels its previous run; runs for
  pushes to `main` and `develop` are never cancelled.
- `timeout-minutes: 30`: a hung run stops after half an hour instead of GitHub's
  default of six hours, which would use up Actions minutes. How to keep it right:
  - **Rule:** about three times the usual run time (Actions tab, duration of recent
    runs). The starter runs in roughly 5-10 minutes, so 30.
  - **When to raise it:** when the usual run time passes a third of the limit (here
    10 minutes). Growth comes from more tests, golden tests, longer code generation
    and new steps such as builds. Raise it in the same change that makes runs longer.
  - **When runs get long** (more than 15-20 minutes), split the job instead of only
    raising the limit: separate `analyze` and `test` jobs that run in parallel, each
    with its own `timeout-minutes`, and shard tests with
    `flutter test --total-shards=<n> --shard-index=<i>`.

Actions are referenced by version tags (`@v7`, `@v2`), not pinned to commit SHAs
([ADR-012](../decisions/ADR-012-repo-and-toolchain-policy.md)).

Builds (APK/IPA) are not part of CI yet.

### Branch protection

A pull request's CI result is only valid for the `develop` it ran against. When another pull
request merges first, an ID both changes added passes CI in each of them and collides in
`develop` ([docs/README.md](../README.md), Requirements). Which safeguard applies depends on
the GitHub plan:

- **If branch protection is available** (a public repository, or a private one on GitHub Pro,
  Team or Enterprise): in Settings → Branches, add a rule for `develop` (and `main`) with
  "Require status checks to pass before merging", the `verify` check, and "Require branches to
  be up to date before merging". GitHub then refuses to merge a stale pull request until it is
  updated from `develop` ("Update branch") and CI passes again.
- **If it is not** (a private repository on GitHub Free): nothing enforces it. Before merging,
  if `develop` has moved since the pull request's last CI run, re-run CI (a pull request run
  checks the merge with the current `develop`) or merge `develop` into the branch, and wait
  for CI to pass. If a collision slips through, CI fails on the push to `develop`; fix it right away by
  renumbering the second change's IDs.

## Native splash

Configured in `flutter_native_splash.yaml`. The generated platform files **are
committed**. They live in `android/app/src/main` and `ios/Runner`, so they are shared
by both flavors and all six iOS build configurations. Regenerate after any change:

```bash
fvm dart run flutter_native_splash:create
```

In a new project, replace:

1. The two logos: `assets/splash/splash_logo.png` (for a light background) and
   `assets/splash/splash_logo_dark.png` (for a dark background). Each is 1152x1152 px
   with a transparent background and the mark inside a centered circle 768 px in
   diameter. They are read by path and are not registered as Flutter assets.
2. The colors in `flutter_native_splash.yaml`: `colorScheme.surface` of
   `AppTheme.light` and `AppTheme.dark`, in both the top level and `android_12`.

Every run rewrites the indentation of `ios/Runner/Info.plist`; its only content
change is the `UIStatusBarHidden` key.

Launch from the app icon when checking the result: Android 12 may skip the splash
when started from an IDE. Reinstall the app first on iOS: it caches the launch screen
and may show a snapshot of the previous run instead, even in the old system theme.

## Launcher icons

Configured per flavor in `flutter_launcher_icons-dev.yaml` and
`flutter_launcher_icons-prod.yaml`, from the sources in `assets/icons/`. The generated
files **are committed**. Regenerate after any change:

```bash
fvm dart run flutter_launcher_icons
```

- Android resources go to `android/app/src/{dev,prod}/res`; there are no launcher icons in
  `src/main`.
- iOS gets `AppIcon-dev` and `AppIcon-prod`. Each of the six build configurations points
  at its flavor's set through `ASSETCATALOG_COMPILER_APPICON_NAME`. The generator matches
  flavors by the name of the `.xcconfig` file and so does not update these settings; they
  were set by hand and do not need to change on regeneration.
- `adaptive_icon_foreground_inset` is `0`, because the source files already keep the
  artwork inside the safe zone.
- There is no dev monochrome file: on Android 13+, themed icons of both flavors look the
  same and differ only by the label.

## Hosted pages

`hosting/` holds the privacy, delete-account and support pages, served by Firebase Hosting
from the **prod project only** (`https://<prod-project-id>.web.app/privacy`, and so on).
`firebase.json` sets `cleanUrls` and `Cache-Control: no-cache`, so a new version shows up
at once. `.firebaserc` has no default project, so a deploy must name one. The user deploys:

```bash
firebase deploy --only hosting --project prod
```

Do not run `firebase init`: it may overwrite `firebase.json`.

## iOS privacy manifest

`ios/Runner/PrivacyInfo.xcprivacy` belongs to the Runner target and declares no tracking,
no data collected by the app's own code and no required reason APIs used directly. Plugins
and SDKs ship their own, except the Analytics binary frameworks. If app code starts using a
required reason API directly, declare it here. How to check:
[store-release.md](store-release.md), iOS.

## New project and store release

- Turning a copy of the starter into a new app: [new-project.md](new-project.md).
- Checklist and data declarations: [store-release.md](store-release.md).

## Change reviewer (Claude Code)

Step 4 of the change workflow runs the `change-reviewer` agent
(`.claude/agents/change-reviewer.md`, [ADR-014](../decisions/ADR-014-change-reviewer.md)). Its
Bash calls go through the hook `.claude/hooks/review-bash.sh`, which needs:

- **`jq`** on the machine (`brew install jq` on macOS; GitHub's Ubuntu runners have it).
  Without it the hook blocks every command of the agent, so a review that cannot run any
  check usually means `jq` is missing.
- **Workspace trust** accepted for the project folder in Claude Code. Until then Claude Code
  does not run the hook, and the agent's limits rest on its instructions alone.
