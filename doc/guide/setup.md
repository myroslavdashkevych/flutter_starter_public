# Setup

## Quick start

You need:

- [FVM](https://fvm.app): installs the Flutter version from `.fvmrc` ("FVM").
- Xcode (iOS) and Android Studio or the Android SDK (Android).
- FlutterFire CLI: every iOS build calls it, and it generates the Firebase configs
  ("Firebase").
- Firebase CLI: only for `flutterfire configure`, which uses it and its login, for
  deploying the hosted pages and for uploading Crashlytics symbols.

Then, from the project root:

```bash
fvm install
fvm flutter pub get
fvm dart run build_runner build
fvm flutter gen-l10n
fvm flutter run --flavor dev --dart-define-from-file=config/dev.json
```

The repository ships without Firebase configs ("Committing Firebase configs"), so
`flutter run` works only after you connect your own Firebase projects
([new-project.md](new-project.md), Connect your own Firebase projects). Analyze and the tests
work without them.

For prod: `--flavor prod --dart-define-from-file=config/prod.json` ("Flavors"). When
building, running or analyzing fails: [troubleshooting.md](troubleshooting.md).

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
  stable Flutter; the version it was last verified with is in
  [spec/tech-stack.md](../spec/tech-stack.md), Verified toolchain. The trade-off: CI and
  fresh clones pick up a new stable release as soon as it ships, so a Flutter release can
  break the build without any change in the repository. A project created from the template
  may pin an exact version instead (`fvm use <version>`).
- All commands use `fvm flutter` / `fvm dart`.
- To upgrade Flutter: change `.fvmrc`, run `fvm install`, then every step of
  [doc/workflow.md](../workflow.md), Verification, and update the verified toolchain
  ([spec/tech-stack.md](../spec/tech-stack.md), Verified toolchain). Changing the FVM setup
  needs the user's approval (global rule).

## Platforms

Android and iOS only. Web, macOS, Windows and Linux folders are not created.

- Android `minSdk`: `flutter.minSdkVersion` in `android/app/build.gradle.kts`, which is
  24 on the verified Flutter version ([spec/tech-stack.md](../spec/tech-stack.md),
  Verified toolchain). It is not pinned, so it follows the Flutter version from `.fvmrc`.
- iOS deployment target: 15.0, set in `ios/Runner.xcodeproj/project.pbxproj` for all six
  build configurations.
- Android `compileSdk` and `targetSdk`: 37, set explicitly in
  `android/app/build.gradle.kts`. `flutter_local_notifications` 23 requires `compileSdk` 37.

## Flavors

| | dev | prod |
|---|---|---|
| Android product flavor | `dev` (`applicationIdSuffix ".dev"`) | `prod` |
| iOS build configurations | `Debug-dev`, `Profile-dev`, `Release-dev` | `Debug-prod`, `Profile-prod`, `Release-prod` |
| iOS scheme | `dev` | `prod` |
| Runtime config | `config/dev.json` | `config/prod.json` |
| Firebase options | `lib/app/config/firebase/firebase_options_dev.dart` | `lib/app/config/firebase/firebase_options_prod.dart` |
| Android Firebase file | `android/app/src/dev/google-services.json` | `android/app/src/prod/google-services.json` |
| iOS Firebase file | `ios/flavors/dev/GoogleService-Info.plist` | `ios/flavors/prod/GoogleService-Info.plist` |

- One `main.dart`. The flavor is read from `appFlavor`
  (`package:flutter/services.dart`) only in `app/bootstrap.dart` and mapped to a
  `Flavor` enum in `app/config/flavor.dart`. A missing or unknown value fails at
  startup. `bootstrap` builds `AppConfig` and passes it to DI
  (`configureDependencies`); `App` receives the router and `SettingsBloc` through
  its constructor. So tests do not depend on `appFlavor` (it is null in
  `flutter test`).
- iOS has only the six configurations above and the `dev` and `prod` schemes; the
  default `Debug`, `Profile`, `Release` and the `Runner` scheme are removed, so
  running without `--flavor` does not work on either platform.
- iOS plugins use Swift Package Manager, so there is no `ios/Podfile`. If one is
  ever added, its `project 'Runner'` mapping must cover all six configurations:
  `Debug-*` → `:debug`, `Profile-*` and `Release-*` → `:release`.
- `config/*.json` holds the API base URLs, the character cache TTL, the privacy policy URL and
  the default of the "Share usage data" setting. `AppConfig` reads them. Only non-secret
  values: [spec/security.md](../spec/security.md), Secrets and the repository.
- Every run needs `--flavor` and `--dart-define-from-file`; the commands are in
  "Quick start" and `CLAUDE.md` (Commands).
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

The agent prepares these commands and the user runs them in their own terminal: they need the
user's Google login ([spec/security.md](../spec/security.md), Agent access). Check flags
against `flutterfire configure --help` of the installed version before running.

```bash
# dev: run once per iOS build configuration (Debug-dev, Profile-dev, Release-dev)
flutterfire configure \
  --yes \
  --project=your-firebase-project-dev \
  --platforms=android,ios \
  --out=lib/app/config/firebase/firebase_options_dev.dart \
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
  --out=lib/app/config/firebase/firebase_options_prod.dart \
  --android-package-name=com.yourcompany.flutterstarter \
  --android-out=android/app/src/prod/google-services.json \
  --ios-bundle-id=com.yourcompany.flutterstarter \
  --ios-build-config=Debug-prod \
  --ios-out=ios/flavors/prod/GoogleService-Info.plist
```

Checked against the FlutterFire CLI version in
[spec/tech-stack.md](../spec/tech-stack.md), Verified toolchain. `--yes` lets repeated runs
overwrite the Dart options file without a prompt. Besides the config files, the command adds the
Google Services and Crashlytics plugins to the Gradle files, adds two build phases
to the `Runner` target and writes `firebase.json` in the project root. Those build
phases call `flutterfire` and read `firebase.json`, so every iOS build needs the
FlutterFire CLI installed.

### Restrict the API keys (done by the user)

Why the keys are restricted, and what this does not protect:
[spec/security.md](../spec/security.md), Secrets and the repository. Do it in each Firebase
project (dev and prod), in Google Cloud Console → APIs & Services → Credentials, for the API
keys the Android and iOS apps use:

1. **API restrictions:** open each key and check that it is restricted to Firebase-related
   APIs.
   Firebase restricts the keys it creates (older keys were restricted in May 2024). Do not
   remove APIs from the list: Firebase services then fail. When you enable a new API that the
   app calls with this key, add it to the list.
2. **Android key → Application restrictions → Android apps:** add the flavor's
   applicationId ("Identifiers") with the SHA-1 of every key that signs its builds: the debug
   key for local runs, and for prod also the upload key and the Play App Signing key
   ([store-release.md](store-release.md), Android). One entry per package name and SHA-1.
   `./gradlew signingReport` in `android/` prints the SHA-1 of the debug key, and of the
   upload key once `android/key.properties` exists; the Play App Signing SHA-1 is in Play
   Console → Setup → App signing.
3. **iOS key → Application restrictions → iOS apps:** add the flavor's bundle ID.
4. **Check:** sign in from a build of each flavor on both platforms.
   A key that no longer matches the app makes Firebase calls fail. Test a change to a prod
   key that is already in use on a test key first.

### Services per platform

| Service | Android | iOS |
|---|---|---|
| Auth (email/password) | Yes | Yes |
| Crashlytics | Yes | Yes |
| Analytics | Yes | Yes |
| Push (FCM) | Yes | Code present; needs an APNs key (Apple Developer Program), not configured |

### Committing Firebase configs

- The starter ships **without** Firebase configs. `lib/app/config/firebase/firebase_options_*.dart`
  are placeholders that throw at startup; the Android and iOS config files and the
  `flutter` section of `firebase.json` are missing. Analyze, the import check and the
  tests do not need them, so CI works. `flutterfire configure` (Generate configs) writes
  them.
- A project created from the template commits its configs, so the app runs after
  cloning. Why this is safe: [spec/security.md](../spec/security.md), Secrets and the
  repository; how the API keys are restricted: "Restrict the API keys".

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

The rules: [spec/security.md](../spec/security.md). What is already set up:

- `.gitignore` excludes secrets from the first commit: `.env` files, keystores,
  `key.properties`, service-account JSON files and the Firebase CLI deploy cache.
- Release signing configs are read from `android/key.properties`. When it does not exist,
  release builds use the debug key, so they cannot be published.
  Format: [store-release.md](store-release.md), Android.
- The Firebase API keys need restricting by you, in each Firebase project: "Restrict the API
  keys".
- CI runs with a read-only token and actions pinned to commit SHAs: "CI (GitHub Actions)".
- Dependabot updates dependencies and actions, and its alerts are on: "Dependabot".
- Store builds are obfuscated, with the symbols uploaded to Crashlytics:
  [store-release.md](store-release.md), Crashlytics symbols.

In a new repository created from the template, the repository settings are set again
([new-project.md](new-project.md), Create the repository).

## Generated code

- Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`, `lib/l10n/gen/`)
  are **not committed**. They are listed in `.gitignore` and produced by
  `build_runner` and gen-l10n locally and in CI. The cost: after a fresh clone, run
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
checks of [doc/workflow.md](../workflow.md), Verification: the format check, analyze, the
import rules ([spec/architecture.md](../spec/architecture.md), Import rules), the spec
conventions (`tool/check_spec.dart`, [doc/workflow.md](../workflow.md), Requirements, whose
toolchain warning appears as an annotation and never fails the job) and the
tests.

The spec check runs with `--base`: the target branch (`origin/<base_ref>`) on a pull request,
the previous tip (`github.event.before`) on a push, and no base on a branch's first push. It
fails when a requirement or screen ID of the base disappeared without being retired. For
this the checkout uses
`fetch-depth: 0`; a shallow clone has no base revision, and the step would exit 2.

The last step warns, once per folder, while `doc/change/` holds anything besides
`_template`. A change may land in several pull requests, so its folder stays in `develop` until
the last one deletes it ([doc/workflow.md](../workflow.md), Changes). The warning keeps a
forgotten folder visible and never fails the job.

The runner may call `flutter`/`dart` directly: the FVM-only rule applies to work
on developer machines, and the runner installs exactly the version from `.fvmrc`.

The token settings (`permissions`, `persist-credentials`) and the SHA pins of actions
follow [spec/security.md](../spec/security.md), Dependencies and CI. Other settings in the
workflow; keep them when you change it:

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

Builds (APK/IPA) are not part of CI yet.

### Dependabot

`.github/dependabot.yml` checks `pub` packages and GitHub Actions once a month (on the first
day) and opens version update pull requests into `develop`
([spec/security.md](../spec/security.md), Dependencies and CI):

- Minor and patch updates of one ecosystem come in one grouped pull request; each major update
  comes in its own, because it may need code changes.
- Commits and titles start with `chore:` (`pub`) or `ci:` (actions). Branches are named
  `dependabot/<ecosystem>/...`, the exception to `<type>/<slug>`
  ([doc/workflow.md](../workflow.md), Changes).
- CI runs on them as on any pull request. A `pub` update changes `pubspec.yaml` and
  `pubspec.lock`; check its changelog, and merge it yourself once CI passes.
- `pub` uses `versioning-strategy: increase`: an update raises the lower bound in
  `pubspec.yaml` to the new version (`^5.8.0` becomes `^5.9.0`), so a project made from the
  starter resolves current versions even when its lock file is regenerated. Without the key,
  Dependabot guesses between `increase` (apps) and `widen` (libraries).
- `pub` has `open-pull-requests-limit: 3`: while three of its pull requests are open, no new
  one is opened, so unreviewed major updates do not pile up. Actions keep the default of 5.

Repository settings (Settings → Code security), once per repository; why:
[spec/security.md](../spec/security.md), Dependencies and CI.

- **Dependabot alerts:** on.
- **Dependabot security updates:** off.

After the first run, Insights → Dependency graph → Dependabot shows both ecosystems with a
successful last check.

### Branch protection

A pull request's CI result is only valid for the `develop` it ran against. When another pull
request merges first, an ID both changes added passes CI in each of them and collides in
`develop` ([doc/workflow.md](../workflow.md), Requirements). Which safeguard applies depends on
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

## Theme

The theme in `lib/presentation/_shared/theme` sets the colors and fonts of the UI; custom
icons go there too. Who owns the look:
[doc/workflow.md](../workflow.md), Source of truth; how widgets read it:
[spec/code-style.md](../spec/code-style.md), Widgets.

### Colors

- `theme/const/app_color.dart` (`AppColor`) holds every color value, as seeds. `AppTheme`
  builds the light and the dark `ColorScheme` from `AppColor.seed` with
  `ColorScheme.fromSeed`.
- Roles that `ColorScheme` lacks (`success`, `warning`) are in `AppColorExtension`
  (`theme/app_color_extension.dart`). Each role and its on-color are `primary` and
  `onPrimary` of a scheme built from the role's seed.
- To change a color, replace its seed. `fromSeed` does not use the seed as is: `primary`
  keeps its hue, with tone and chroma set by Material 3. When the design fixes an exact
  color, override `primary:` in `AppTheme`; its contrast is then checked only by ACC-3.
- To add a role: a seed in `AppColor`, a field in `AppColorExtension` (constructor, `of`,
  `copyWith`, `lerp`), and the pair in `app_color_extension_test.dart`, which fails when an
  on-color is below WCAG AA contrast. ACC-3 checks the text of every screen in both themes.
- After changing `AppColor.seed`, check the splash colors ("Native splash").

### Fonts

- Files: `assets/font/<family>/`, static TTFs of weights 400 and 500 (the ones the
  Material 3 text theme uses), with the font's `OFL.txt` in the same folder. Static files
  work with the `fontWeight` of the text theme without extra code.
- The license must allow bundling in an app, such as the SIL Open Font License 1.1, and the
  font must cover Cyrillic as long as the app ships Ukrainian. Fonts are bundled, not loaded by a
  package at run time: they work offline and send no request to a font service.
- Each family is declared under `flutter: fonts:` in `pubspec.yaml`, with `weight: 500` on
  the Medium file. The family name there equals the value in `theme/const/app_font.dart`
  (`AppFont`).
- `AppTheme` sets `AppFont.heading` on the display, headline and title roles and
  `AppFont.body` on the rest. For one family, give both the same name.
- Tests render text with the test font, so only the running app shows the fonts: check an
  app bar title (heading) and list text (body) in both languages.

### Icons

- UI icons come from Material `Icons` (`uses-material-design: true` in `pubspec.yaml`).
- Icons the design adds come as an icon font, so they take their color and size from the
  theme like any `Icon` and need no package:
  1. Build the font from single-color SVGs with FlutterIcon (fluttericon.com), which also
     gives the Dart class.
  2. Put the TTF and its license in `assets/font/<name>/` and declare it under
     `flutter: fonts:`.
  3. Put the `IconData` constants in one class in `theme/const/` (`app_icon.dart` ->
     `AppIcon`): `static const IconData star = IconData(0xe800, fontFamily: 'AppIcon');`.
     `fontFamily` is the family name from `pubspec.yaml`. Rewrite the class the generator
     gives to follow [spec/code-style.md](../spec/code-style.md) instead of excluding it
     from analysis.
  4. Keep every `IconData` `const`: release builds keep only the used glyphs, and a
     non-constant `IconData` fails the release build.
- Multi-color icons and illustrations need an SVG package. Adding one is a `pubspec.yaml`
  change through the usual change process.
- Launcher icons are separate: "Launcher icons".

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
(`.claude/agents/change-reviewer.md`). Its limits are the agent access policy, as for every
session ([spec/security.md](../spec/security.md), Agent access), so it needs **workspace
trust** accepted for the project folder in Claude Code: until then Claude Code does not apply
the project's `.claude/settings.json`.

## Agent sandbox

`.claude/settings.json` turns on the Claude Code sandbox (Seatbelt on macOS). It needs no
install on macOS. The policy rules: [spec/security.md](../spec/security.md), Agent access.
What each sandbox entry is for:

- `filesystem.allowWrite`: the caches Flutter, Dart and FVM write outside the project
  (`~/fvm`, `~/.pub-cache`, `~/.dartServer`, `~/.dart-tool`, `~/.flutter`,
  `~/.config/flutter`).
- `filesystem.allowRead`: `android/local.properties`, which the Flutter tool reads and rewrites
  on every command. Claude's file tools still cannot read it.
- `network.allowLocalBinding`: `flutter test` starts a local HTTP server. A sandboxed process
  can then listen on every interface, not only `localhost`.
- `network.deniedDomains`: GitHub, so no command can push.
- No `excludedCommands` ([spec/security.md](../spec/security.md), Agent access, `sandbox`).
  Inside the sandbox, `fvm flutter build` and `fvm flutter run` fail: Gradle needs the network
  and `~/.gradle`.

`git status` prints "Operation not permitted" for the Firebase configs inside the sandbox
and still works.
