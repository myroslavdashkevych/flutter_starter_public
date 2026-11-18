# New Project

How to turn a copy of this starter into a new app, in order. Each step links to the
document that holds the details.

## 1. Create the repository

Create a repository from this template on GitHub, with "Include all branches" off, so the
copy has only `main`, and clone it. Then create a `develop` branch from `main` and push it: it
stays for good, and every change, including the steps below, goes on its own branch from it
([doc/workflow.md](../workflow.md), Changes); the rename in step 2, for example, on
`chore/init-project`.

A template copies files, not repository settings. Set them in the new repository:

- [ ] Dependabot in Settings → Code security ([setup.md](setup.md), Dependabot).
- [ ] Branch protection for `develop` and `main`, if your GitHub plan has it
  ([setup.md](setup.md), Branch protection).

## 2. Rename with `tool/init_project.dart`

`tool/init_project.dart` is pure Dart, with no extra dependencies. It is a project-wide
rename, so an agent runs it only when the user explicitly asks. Run it from the project
root of a fresh copy, first with `--dry-run`, which prints all changes and writes nothing:

```bash
fvm dart run tool/init_project.dart \
  --name "My App" \
  --package my_app \
  --org com.yourdomain \
  --firebase-prefix my-app-demo \
  --dry-run
```

Then run the same command without `--dry-run`.

| Option | Rule | Result |
|---|---|---|
| `--name` | Not empty, no `"`, `\`, `$`, `&`, `<`, `>` or line breaks | App name; the dev flavor adds ` Dev` |
| `--package` | `snake_case`, not a reserved word | Dart package name |
| `--org` | Reverse domain with at least two segments | With `--package` without underscores, the application ID: `com.yourdomain.myapp`, and `.dev` for dev. iOS bundle IDs do not allow underscores |
| `--firebase-prefix` | 6-26 lowercase letters, digits and hyphens, starts with a letter, does not end with a hyphen | Firebase project IDs `<prefix>-dev` and `<prefix>`, which must fit 6-30 characters |

It refuses to run when the git working tree is not clean (also with `--dry-run`), or when
the project is already initialized. The IDs must also differ from the starter's.

It updates:

- `pubspec.yaml`: `name` and `description`;
- own package imports in tracked Dart files, and the package name in
  `tool/check_imports.dart` and its test;
- Android: `namespace`, `applicationId`, flavor app names, and the package of `MainActivity`,
  whose file moves to the new package path;
- iOS: bundle IDs of all six build configurations of `Runner` and `RunnerTests`,
  `APP_DISPLAY_NAME` and `CFBundleName`;
- `appTitle` in both ARB files;
- `.firebaserc`, the hosting URLs in `config/*.json`, and the identifiers in
  `doc/guide/setup.md`.

It does not touch Firebase or any account, does not run `flutterfire`, and deletes nothing
except the old empty `MainActivity` folders. It skips itself and its test, which keep the
starter's identifiers, and `lib/app/config/firebase/`.

At the end it prints the IDs of the two Firebase projects to create, the six
`flutterfire configure` commands, the commands that regenerate and check the code, what to
replace by hand ("Replace the starter's content") and a reminder about the demo blocks
("Demo and optional blocks"). `fvm dart format lib test tool` is part of those
commands, because a new package name changes how lines wrap and CI checks the format.

The app does not compile until the code is generated, because generated files are not
committed ([setup.md](setup.md), Generated code):

```bash
fvm flutter pub get
fvm dart run build_runner build
fvm flutter gen-l10n
```

## 3. Connect your own Firebase projects

Create the two Firebase projects ([setup.md](setup.md), Firebase, "Done by the user"), then
run the `flutterfire configure` commands the script printed ([setup.md](setup.md), Firebase,
"Generate configs"), then restrict the API keys of both projects ([setup.md](setup.md),
Restrict the API keys).

The starter ships without Firebase configs ([setup.md](setup.md), Committing Firebase
configs), and the script warns about it. Until they are generated:

- the Android build fails in the Google Services plugin, because `google-services.json`
  is missing;
- the iOS build fails in the FlutterFire build phases;
- the app throws at startup, because `lib/app/config/firebase/firebase_options_*.dart` are
  placeholders.

## 4. Replace the starter's content

- [ ] **Launcher icons.** The five files in `assets/icons/`, then regenerate:
  ```bash
  fvm dart run flutter_launcher_icons
  ```
  Keep the artwork of the foreground and monochrome files inside the adaptive icon safe
  zone (the center 66 of 108 dp): the configs set `adaptive_icon_foreground_inset: 0`.
  Update the background color in `flutter_launcher_icons-*.yaml` too. Details in
  [setup.md](setup.md), Launcher icons.
- [ ] **Notification icon.** `notification_notif_data_source.dart` uses
  `@mipmap/ic_launcher` as the small icon, and Android draws a small icon from its alpha
  channel only. Check how it looks in the status bar; a dedicated white-on-transparent
  icon may be needed.
- [ ] **Splash logo and colors.** [setup.md](setup.md), Native splash.
- [ ] **Spacing tokens.** Replace the values in
  `lib/presentation/_shared/theme/const/app_spacing.dart` with the scale of your design; keep
  the role names or rename them across `lib/presentation/`.
- [ ] **Colors.** Replace the seeds in
  `lib/presentation/_shared/theme/const/app_color.dart` ([setup.md](setup.md), Colors).
- [ ] **Fonts.** Replace the files in `assets/font/`, the families under `flutter: fonts:` in
  `pubspec.yaml` and the names in `lib/presentation/_shared/theme/const/app_font.dart`
  ([setup.md](setup.md), Fonts).
- [ ] **Icons.** If the design has its own icons, add them as an icon font
  ([setup.md](setup.md), Icons).
- [ ] **Hosting pages.** `hosting/*.html`: follow the `CHANGE FOR A NEW PROJECT` comment
  at the top of each page. Name the legal entity in the privacy policy, and rewrite the
  data table if the SDKs or a backend differ.
- [ ] **Hosting project.** The prod project in `.firebaserc`. Enable Hosting in the prod
  project only.
- [ ] **URLs in config.** `PRIVACY_POLICY_URL` in both `config/*.json` points at the prod
  page.
- [ ] **Contact.** The contact email on all three hosting pages and in both store
  consoles.
- [ ] **Root README.md and CLAUDE.md.** The project name and description.
- [ ] **Backend data.** If a backend stores user data, account deletion must delete it as
  well ([spec/behavior/profile.md](../spec/behavior/profile.md), Scope), and
  `delete-account.html` must say so.

Deploy the pages ([setup.md](setup.md), Hosted pages), then open each URL:

```bash
firebase deploy --only hosting --project prod
```

### Replace the spec

Do this together with the demo blocks ("Demo and optional blocks" below).

- [ ] **Product.** Replace `doc/spec/product.md` with your app's vision, users, scope and
  non-goals.
- [ ] **Behavior.** Delete the behavior and implementation files of every removed block
  (`doc/spec/behavior/<area>.md`, `doc/spec/implementation/<area>.md`), and write your own behavior
  specs with requirement IDs, scenarios and screens ([doc/workflow.md](../workflow.md), Requirements, Screens). Update the
  files of the blocks you keep where your app differs. A requirement lands together with a test
  named by its ID, or with its ID on the `Manual` line, or CI fails with `coverage:`; so write
  the spec of a new area in the change that implements it.
- [ ] **Baseline.** Keep `doc/spec/architecture.md` and `doc/spec/tech-stack.md` as your
  baseline; change them through the usual change process. Write your own decisions as
  `ADR-001` onwards in `doc/decision/`.
- [ ] **Design.** Empty `doc/design/screen/` (keep `.gitkeep`) and record your design tool in
  `doc/design/README.md`.
- [ ] **Check.** Search the spec for what is left of the demo:
  ```bash
  grep -rnE 'CHR-|FAV-|SCR-(5|6|8)\b|Rick and Morty|character_list|character_detail|favorite' doc/spec
  ```
  Replace every hit, or keep it deliberately (for example when you keep the favorites block).
  Then run `fvm dart run tool/check_spec.dart`. It takes the prefixes from your behavior files,
  so it no longer recognizes the IDs of a deleted area; the search above finds those. In CI it
  also compares with the base branch (`--base`), which skips a prefix that no behavior file uses
  any more, so deleting a whole area passes. A requirement removed from a file you keep (for
  example the favorites parts of `navigation.md` or `profile.md`) goes to that file's `Retired`
  line, or CI fails with `removed:`, on a pull request and on a push to `main` or `develop`
  alike. Screen numbers are global: add the screens of deleted blocks (for example SCR-5, SCR-6
  and SCR-8 without characters and favorites) to the `Retired` line of a behavior file you keep. Do
  not renumber the remaining screens: the base comparison rejects it, as it reuses numbers.
  The local command is in [doc/workflow.md](../workflow.md), Requirements.

## 5. Demo and optional blocks

The starter is a core plus four blocks. Remove the demo blocks in every project; remove an
optional block when the app does not need it.

| Block | Kind | Depends on | Removal checked |
|---|---|---|---|
| A. Characters (Rick and Morty API) | Demo, replaced by your first feature | — | Analyzer only: it is the first tab ("A. Characters") |
| B. Favorites | Demo | A, D | Analyze, import check, format, all tests |
| C. Push notifications | Optional | A (the permission trigger only) | Analyze, import check, format, all tests, dev debug APK |
| D. Auth and profile | Optional | — (remove B first) | Analyze, import check, format, all tests, with B removed |

Everything else is the core and stays: `app/` (DI, router, bootstrap, observability,
link), `shared/`, `domain/_shared`, `domain/use_case/settings`,
`domain/use_case/observability`,
`data/_shared`, `presentation/_shared` (theme, l10n, component, widget), settings, the home
shell, crash reporting, analytics and the hosting setup.

`domain` has no area folders ([spec/architecture.md](../spec/architecture.md), Inside
`domain`), so a block's domain part is a list of files in `domain/entity` and
`domain/repository` and its use case group in `domain/use_case/<area>`, given for each
block below, with the same group in `test/domain/use_case`. Its analytics events are
variants of `domain/_shared/service/analytics/analytics_event.dart` with their cases in
`data/_shared/service/analytics/firebase_analytics_service.dart` and its test.

Order: B before A and before D, because favorites store characters for a signed-in user. Do A
when your first feature is ready to take its tab.

The removal steps were checked on 2026-11-03 in a scratch copy of the starter, one block at
a time; the "Removal checked" column says how far.

### How to remove a block

1. Delete the block's folders and files, and their tests.
2. Edit the shared files listed for the block.
3. Remove the block's keys from both ARB files.
4. Run `fvm dart run build_runner build` **after all edits**. Generated files such as
   `routes.g.dart` and `injection.config.dart` still refer to deleted classes until then,
   and `fvm flutter analyze` does not show it, because generated files are excluded from
   analysis.
5. Run `fvm flutter gen-l10n`, then [doc/workflow.md](../workflow.md), Verification: analyze,
   the import check, all tests and the format check. Run every test: some references fail only at
   run time, such as a DI registration or a list of tabs.
6. Update the docs and the hosting pages listed for the block.
7. Remove the packages that are no longer used. This is a `pubspec.yaml` change: an agent
   asks first. Then run `fvm flutter pub get`.

### B. Favorites

Delete `lib/data/favorite`, `lib/presentation/favorite_list`,
`lib/presentation/_shared/component/favorite_toggle` and the same three folders under `test/`; in
`lib/domain` the entities `user_favorites.dart` and `favorite_mark.dart`, the contract
`favorite_repository.dart` and the use case group `use_case/favorite` with its tests; and
`test/helper/fake_favorite_repository.dart`.

Edit:

- `app/router/routes.dart`: `FavoriteListRoute` and `FavoriteDetailRoute` with their entries in
  the profile branch, their screen names, `_favoriteToggle` and every
  `favoriteToggleBuilder` argument.
- `presentation/character_list/page/character_list_page.dart` and
  `presentation/character_detail/page/character_detail_page.dart`: the `favoriteToggleBuilder`
  parameter; in the details page also `notFoundActionBuilder`, which only favorites use.
- `presentation/profile/page/profile_page.dart`: `onFavorites` and the Favorites entry.
- `domain/use_case/auth/delete_account_use_case.dart`: the `FavoriteRepository`
  dependency, the user id read before deletion and `clearForUser`.
- Analytics: `favoriteAdded` and `favoriteRemoved`.
- ARB keys: `favoriteListTitle`, `favoriteListGuestMessage`, `favoriteListEmpty`,
  `favoriteAdd`, `favoriteRemove`.
- Tests: `MockFavoriteRepository` in `test/helper/mock.dart`; the favorites setup in
  `app_test.dart`, `app_router_test.dart` and `app_router_auth_test.dart` (plus its
  favorites group and the sign-in from the favorites page); the profile bloc and page
  tests; the toggle groups and "opened from favorites" in the characters list and character
  details page tests; `delete_account_use_case_test.dart`.

Docs and pages: `doc/spec/behavior/favorite.md` and `doc/spec/implementation/favorite.md`, and the
favorites parts of `doc/spec/behavior/navigation.md`, `character.md` (toggle and details states),
`profile.md` and `doc/spec/implementation/profile.md`; the favorites rows and examples in
`doc/spec/architecture.md` (`component/favorite_toggle/` in Folder structure and Inside
`presentation/_shared`; the storage table in Local storage;
Routing); the feature list in `doc/spec/product.md`; `hosting/privacy.html` and `hosting/delete-account.html`.

Packages: none become unused; `hive_ce` still holds the characters cache.

### A. Characters

Characters is the first tab and the initial location, so it is replaced rather than removed. Add
your first feature as the first branch of the shell first, then delete the demo. Its tests
in the router tests are rewritten around your feature at the same time.

Delete `lib/data/character`, `lib/presentation/character_list`,
`lib/presentation/character_detail`, `lib/app/di/config_module/character_module.dart`,
`lib/presentation/_shared/widget/image`, `lib/presentation/_shared/widget/tile`,
`lib/presentation/_shared/l10n/character_status_label.dart`; in `lib/domain` the entity
`character.dart` (`_shared/wrapper/pagination` stays for your API), the contract
`character_repository.dart` and the use case group `use_case/character`; under `test/` the same
folders and `test/helper/character_fixture.dart`.

Edit:

- `app/router/routes.dart`: the Characters branch, `CharacterListRoute`, `CharacterDetailRoute`,
  their screen names and `_characterListObserver` (every branch has its own observer, listed in branch order in
  `_branchObservers`). Move the notification permission trigger from `CharacterDetailRoute` to
  your feature (NTF-1 in `doc/spec/behavior/notification.md`).
- `app/router/app_router.dart`: `initialLocation`.
- `app/bootstrap.dart`: `CharacterHiveDataSource` in `_evictExpiredCaches`. If your feature
  caches API data, its data source implements `ExpiringCache` and takes this place
  (`doc/spec/architecture.md`, Local storage); `check_imports` fails until it does.
- `presentation/home_shell/page/home_shell_page.dart`: the Characters destination.
- `AppConfig`, `config/*.json` and `app/di/config_module/character_module.dart`:
  `CHARACTER_CACHE_TTL_MINUTES`.
  `RICK_AND_MORTY_API_BASE_URL` feeds `publicDio`: point it at your third-party API and rename
  it, or remove both.
- Analytics: `searched` and `characterOpened`.
- ARB keys: `navCharacterList`, `characterListSearchHint`, `characterListEmpty`,
  `characterListNoResults`, the three `characterStatus*` and the seven `characterDetail*` keys.
- Tests: `MockCharacterRepository` in `test/helper/mock.dart`; `app_test.dart`,
  `app_router_test.dart` and `app_router_auth_test.dart`, which navigate through
  `/character-list`; `app_config_test.dart` and `injection_test.dart` (config values);
  `notification_wiring_test.dart` uses `/character-list` routes only as examples.

Docs and pages: `doc/spec/behavior/character.md`, `doc/spec/implementation/character.md` and the
characters parts of `doc/spec/behavior/navigation.md`; the feature list in
`doc/spec/product.md`; the sentence about the character use cases in
`doc/spec/architecture.md`, Data flow (its naming examples may stay), and `image/` and
`tile/` in its Folder structure and Inside `presentation/_shared`; the **Behavior:** line of
`doc/spec/implementation/network.md`, which links `behavior/character.md`; `hosting/privacy.html` (the Rick and Morty API and the cached characters); `doc/README.md`, One request, end to end, and Reading order, which trace the characters list: retrace them through one of your own screens.

Packages that may become unused: `cached_network_image_ce`, `stream_transform`; with B gone
too, `hive_ce` and `hive_ce_flutter` (then also `initHive` in `bootstrap.dart` and the
folder `data/_shared/data_source/hive/`).

Checked: after deleting the block, compile errors appear only in `routes.dart`,
`test/helper/mock.dart` and the three app and router tests above.

### C. Push notifications

Delete `lib/data/notification`, `lib/app/notification`,
`lib/presentation/_shared/widget/dialog/notification_permission_dialog.dart`; in
`lib/domain` the entity `notification_message.dart`, the contract
`notification_repository.dart` and the use case group `use_case/notification` with its
tests; `test/data/notification`, `test/app/notification` and
`test/helper/fake_notification_repository.dart`.

Edit:

- `app/bootstrap.dart`: `_setUpNotifications`, the `onBackgroundMessage` handler,
  `openTappedNotifications` and their imports.
- `app/router/routes.dart`: `_askForNotificationPermission` and the `_AskOnFirstLoad` widget
  that calls it; both details routes then pass `CharacterDetailPage` to their `BlocProvider`
  directly.
- `android/app/src/main/AndroidManifest.xml`: the
  `com.google.firebase.messaging.default_notification_channel_id` and
  `firebase_messaging_installation_id_enabled` meta-data.
- ARB keys: the four `notificationPermission*` keys and `notificationChannelName`.
- Tests: the `ShouldAskNotificationPermissionUseCase` and
  `RequestNotificationPermissionUseCase` registrations in `app_router_test.dart` and
  `app_router_auth_test.dart`, and the "notification permission" group in
  `app_router_test.dart`.

Docs and pages: `doc/spec/behavior/notification.md` and
`doc/spec/implementation/notification.md`; `dialog/` in `doc/spec/architecture.md`, Folder
structure and Inside `presentation/_shared`; `doc/guide/store-release.md`, Push
notifications, and the Firebase Cloud Messaging rows in "Declare the data"; the push row in
`doc/guide/setup.md`, Services per platform;
the push parts of `doc/spec/product.md` (Scope, Not included yet) and of
`hosting/privacy.html`.

Packages: `firebase_messaging`, `flutter_local_notifications`. Core library desugaring in
`android/app/build.gradle.kts` exists only for `flutter_local_notifications`
(`doc/spec/tech-stack.md`, Compatibility notes). Removing the packages and desugaring was not part of the
check.

### D. Auth and profile

Remove B first.

Delete `lib/data/auth`, `lib/presentation/auth`,
`lib/presentation/profile`, `lib/app/router/auth_redirect.dart`,
`lib/app/observability/crash_reporting_user_sync.dart`; in `lib/domain` the entity
`app_user.dart`, the contract `auth_repository.dart`, the use case group `use_case/auth` and
`use_case/observability/set_crash_reporting_user_use_case.dart` with their tests; under
`test/` the same three
folders, `test/app/router/auth_redirect_test.dart`, `test/app/router/app_router_auth_test.dart`,
`test/app/observability/crash_reporting_user_sync_test.dart` and
`test/helper/auth_fixture.dart`.

Edit:

- `app/bootstrap.dart`: `getIt<AuthBloc>()` for the router and `syncCrashReportingUser`.
- `app/router/app_router.dart`: the `AuthBloc` parameter and the redirect.
- `app/router/routes.dart`: the sign-in, sign-up and reset-password routes, the Profile
  branch with its observer, and their screen names.
- `presentation/home_shell/page/home_shell_page.dart`: the Profile destination.
- `app/di/config_module/network_module.dart`: the `backendDio` registration, which needs the
  `TokenProvider` from `data/auth` (`AuthFirebaseDataSource`). `AuthInterceptor`,
  `TokenProvider` and
  `createBackendDio` stay in `data/_shared/data_source/network` as the pattern for a backend
  with sign-in.
- Analytics: `signedIn`, `signedUp`, `passwordResetRequested` and `accountDeleted`.
- ARB keys: `navProfile`, the seven `auth*`, four `signIn*`, three `signUp*`, four
  `resetPassword*` and eight `profile*` keys.
- Tests: the auth mocks and the `EmailAuthProvider` fallback value in
  `test/helper/mock.dart`; `app_test.dart` and `app_router_test.dart` (`createAppRouter()`
  without `AuthBloc`, the Profile tab). Two tests fail only at run time:
  `injection_test.dart` (the `backendDio` check) and `home_shell_page_test.dart` (the list
  of tabs).
- Optional: `AuthFailure` in `domain/_shared/wrapper/result/failure.dart`, its messages and the
  `failureAuth*` keys can stay; nothing produces them any more.

Docs and pages: `doc/spec/behavior/auth.md`, `profile.md`, the auth parts of
`navigation.md` and `observability.md`; `doc/spec/implementation/auth.md` and `profile.md`;
`doc/spec/architecture.md`, Dependency injection and Networking;
`doc/spec/security.md`, Tokens and Personal data (the Firebase UID in crash reports);
`doc/spec/implementation/network.md`, AuthInterceptor; the Email Address, User ID and linked Crash
Data rows in `doc/guide/store-release.md`, "Declare the data"; the
authentication line in `doc/spec/product.md`. Without sign-up, the in-app account deletion
requirement does not apply: remove `hosting/delete-account.html` and its link in the store
consoles.

Packages: `firebase_auth`.

## 6. Release

Before submitting to the stores, follow [store-release.md](store-release.md).

## 7. What has been verified

The script was verified on a fresh clone up to the Firebase step: dry run, rename, code
generation, analyze, import check, all tests, and the iOS build settings. On Android, with the
Google Services and Crashlytics plugins removed from that copy, the dev build ran on an
emulator. A build with configs from new Firebase projects has not been run: the first real
project closes this check.
