# New Project

How to turn a copy of this starter into a new app, in order. Each step links to the
document that holds the details.

## 1. Create the repository

Create a repository from this template on GitHub and clone it.

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
  `docs/setup.md`.

It does not touch Firebase or any account, does not run `flutterfire`, and deletes nothing
except the old empty `MainActivity` folders. It skips itself and its test, which keep the
starter's identifiers, and `lib/app/firebase/`.

At the end it prints the IDs of the two Firebase projects to create, the six
`flutterfire configure` commands, the commands that regenerate and check the code, what to
replace by hand (section 4) and a reminder about the demo blocks (section 5). `fvm dart format lib test tool` is part of those
commands, because a new package name changes how lines wrap and CI checks the format.

The app does not compile until the code is generated, because generated files are not
committed (`docs/setup.md` section 7):

```bash
fvm flutter pub get
fvm dart run build_runner build
fvm flutter gen-l10n
```

## 3. Connect your own Firebase projects

Create the two Firebase projects (`docs/setup.md` section 5.1), then run the
`flutterfire configure` commands the script printed (`docs/setup.md` section 5.2).

The starter ships without Firebase configs (`docs/setup.md` section 5.4), and the script
warns about it. Until they are generated:

- the Android build fails in the Google Services plugin, because `google-services.json`
  is missing;
- the iOS build fails in the FlutterFire build phases;
- the app throws at startup, because `lib/app/firebase/firebase_options_*.dart` are
  placeholders.

## 4. Replace the starter's content

- [ ] **Launcher icons.** The five files in `assets/icons/`, then regenerate:
  ```bash
  fvm dart run flutter_launcher_icons
  ```
  Keep the artwork of the foreground and monochrome files inside the adaptive icon safe
  zone (the center 66 of 108 dp): the configs set `adaptive_icon_foreground_inset: 0`.
  Update the background color in `flutter_launcher_icons-*.yaml` too. Details in
  `docs/setup.md` section 11.
- [ ] **Notification icon.** `local_notifications_data_source.dart` uses
  `@mipmap/ic_launcher` as the small icon, and Android draws a small icon from its alpha
  channel only. Check how it looks in the status bar; a dedicated white-on-transparent
  icon may be needed.
- [ ] **Splash logo and colors.** `docs/setup.md` section 10.
- [ ] **Hosting pages.** `hosting/*.html`: follow the `CHANGE FOR A NEW PROJECT` comment
  at the top of each page. Name the legal entity in the privacy policy, and rewrite the
  data table if the SDKs or a backend differ.
- [ ] **Hosting project.** The prod project in `.firebaserc`. Enable Hosting in the prod
  project only.
- [ ] **URLs in config.** `PRIVACY_POLICY_URL` in both `config/*.json` points at the prod
  page.
- [ ] **Contact.** The contact email on all three hosting pages and in both store
  consoles.
- [ ] **README.md and CLAUDE.md.** The project name and description.
- [ ] **Backend data.** If a backend stores user data, account deletion must delete it as
  well (`docs/features.md` section 4), and `delete-account.html` must say so.

Deploy the pages (`docs/setup.md` section 12), then open each URL:

```bash
firebase deploy --only hosting --project prod
```

## 5. Demo and optional blocks

The starter is a core plus four blocks. Remove the demo blocks in every project; remove an
optional block when the app does not need it.

| Block | Kind | Depends on | Removal checked |
|---|---|---|---|
| A. Items (Rick and Morty API) | Demo, replaced by your first feature | — | Analyzer only: it is the first tab (section 5.3) |
| B. Favorites | Demo | A, D | Analyze, import check, format, all tests |
| C. Push notifications | Optional | A (the permission trigger only) | Analyze, import check, format, all tests, dev debug APK |
| D. Auth and profile | Optional | — (remove B first) | Analyze, import check, format, all tests, with B removed |

Everything else is the core and stays: `app/` (DI, router, bootstrap, observability,
links), `shared/`, `domain/_shared`, `data/_shared`, `presentation/_shared` (theme, l10n,
widgets), settings, the home shell, crash reporting, analytics and the hosting setup.

Order: B before A and before D, because favorites store items for a signed-in user. Do A
when your first feature is ready to take its tab.

The removal steps were checked on 2026-11-03 in a scratch copy of the starter, one block at
a time; the "Removal checked" column says how far.

### 5.1 How to remove a block

1. Delete the block's folders and files, and their tests.
2. Edit the shared files listed for the block.
3. Remove the block's keys from both ARB files.
4. Run `fvm dart run build_runner build` **after all edits**. Generated files such as
   `routes.g.dart` and `injection.config.dart` still refer to deleted classes until then,
   and `fvm flutter analyze` does not show it, because generated files are excluded from
   analysis.
5. Run `fvm flutter gen-l10n`, then the verification from `CLAUDE.md`: analyze, the import
   check, all tests and the format check. Run every test: some references fail only at
   run time, such as a DI registration or a list of tabs.
6. Update the docs and the hosting pages listed for the block.
7. Remove the packages that are no longer used. This is a `pubspec.yaml` change: an agent
   asks first. Then run `fvm flutter pub get`.

### 5.2 B. Favorites

Delete `lib/domain/favorites`, `lib/data/favorites`, `lib/presentation/favorites`,
`lib/presentation/_shared/favorites`, the same four folders under `test/`, and
`test/helpers/fake_favorites_repository.dart`.

Edit:

- `app/router/routes.dart`: `FavoritesRoute` and `FavoriteDetailsRoute` with their entries in
  the profile branch, their screen names, `_favoriteToggle` and every
  `favoriteToggleBuilder` argument.
- `presentation/items_list/pages/items_list_page.dart` and
  `presentation/item_details/pages/item_details_page.dart`: the `favoriteToggleBuilder`
  parameter; in the details page also `notFoundActionBuilder`, which only favorites use.
- `presentation/profile/pages/profile_page.dart`: `onFavorites` and the Favorites entry.
- `domain/auth/usecases/delete_account_use_case.dart`: the `FavoritesRepository`
  dependency, the user id read before deletion and `clearForUser`.
- `domain/_shared/services/analytics_events.dart`: `addToWishlist`, `removeFromWishlist`.
- ARB keys: `favoritesTitle`, `favoritesGuestMessage`, `favoritesEmpty`, `favoritesAdd`,
  `favoritesRemove`.
- Tests: `MockFavoritesRepository` in `test/helpers/mocks.dart`; the favorites setup in
  `app_test.dart`, `app_router_test.dart` and `app_router_auth_test.dart` (plus its
  favorites group and the sign-in from the favorites page); the profile cubit and page
  tests; the toggle groups and "opened from favorites" in the items list and item details
  page tests; `delete_account_use_case_test.dart`.

Docs and pages: `docs/features.md` section 9 and the favorites parts of sections 1 and 4;
the favorites rows and examples in `docs/architecture.md` (storage table, `_shared/favorites`,
section 5.8); "Local persistence" in `CLAUDE.md`; the feature list in `README.md`;
`hosting/privacy.html` and `hosting/delete-account.html`.

Packages: none become unused; `hive_ce` still holds the items cache.

### 5.3 A. Items

Items is the first tab and the initial location, so it is replaced rather than removed. Add
your first feature as the first branch of the shell first, then delete the demo. Its tests
in the router tests are rewritten around your feature at the same time.

Delete `lib/domain/items`, `lib/data/items`, `lib/presentation/items_list`,
`lib/presentation/item_details`, `lib/app/di/items_module.dart`,
`lib/presentation/_shared/widgets/item_tile.dart` and `item_image.dart`,
`lib/presentation/_shared/l10n/item_status_labels.dart`, and `lib/domain/_shared/paginated.dart`
unless your API is paginated; under `test/` the same folders,
`test/presentation/_shared/widgets/item_image_test.dart` and `test/helpers/items_fixtures.dart`.

Edit:

- `app/router/routes.dart`: the Items branch, `ItemsRoute`, `ItemDetailsRoute`, their screen
  names and `_itemsObserver` (every branch has its own observer, listed in branch order in
  `_branchObservers`). Move the notification permission trigger from `ItemDetailsRoute` to
  your feature (`docs/features.md` section 6).
- `app/router/app_router.dart`: `initialLocation`.
- `app/bootstrap.dart`: `ItemsLocalDataSource` in `_evictExpiredCaches`. If your feature
  caches API data, its data source implements `ExpiringCache` and takes this place
  (`docs/architecture.md` section 5.6).
- `presentation/home_shell/pages/home_shell_page.dart`: the Items destination.
- `AppConfig`, `config/*.json` and `app/di/items_module.dart`: `ITEMS_CACHE_TTL_MINUTES`.
  `ITEMS_API_BASE_URL` feeds `publicDio`: point it at your third-party API and rename it,
  or remove both.
- `domain/_shared/services/analytics_events.dart`: `search`, `select_content` and their
  parameters and values.
- ARB keys: `navItems`, `itemsSearchHint`, `itemsEmpty`, `itemsNoResults`, the three
  `itemStatus*` and the seven `itemDetails*` keys.
- Tests: `MockItemsRepository` in `test/helpers/mocks.dart`; `app_test.dart`,
  `app_router_test.dart` and `app_router_auth_test.dart`, which navigate through `/items`;
  `app_config_test.dart` and `injection_test.dart` (config values);
  `notifications_wiring_test.dart` uses `/items` routes only as examples.

Docs and pages: `docs/features.md` sections 1 and 3; the feature list in `README.md`; the
sentence about the items use cases in `docs/architecture.md` section 4 (its naming examples
may stay); `hosting/privacy.html` (the Rick and Morty API and the cached items).

Packages that may become unused: `cached_network_image_ce`, `stream_transform`; with B gone
too, `hive_ce` and `hive_ce_flutter` (then also `initHive` in `bootstrap.dart` and
`data/_shared/storage/hive_init.dart`).

Checked: after deleting the block, compile errors appear only in `routes.dart`,
`test/helpers/mocks.dart` and the three app and router tests above.

### 5.4 C. Push notifications

Delete `lib/domain/notifications`, `lib/data/notifications`, `lib/app/notifications`,
`lib/presentation/_shared/notifications`, `test/domain/notifications`,
`test/data/notifications`, `test/app/notifications` and
`test/helpers/fake_notifications_repository.dart`.

Edit:

- `app/bootstrap.dart`: `_setUpNotifications`, the `onBackgroundMessage` handler,
  `openTappedNotifications` and their imports.
- `app/router/routes.dart`: `_askForNotificationPermission`; its callers become
  `getIt<ItemDetailsCubit>()..open(id)`. The `onLoaded` callback of `open` then has no
  caller in the app; it stays with its tests.
- `data/_shared/services/firebase_services_module.dart`: the `FirebaseMessaging` and
  `FlutterLocalNotificationsPlugin` providers.
- `android/app/src/main/AndroidManifest.xml`: the
  `com.google.firebase.messaging.default_notification_channel_id` and
  `firebase_messaging_installation_id_enabled` meta-data.
- ARB keys: the four `notificationPermission*` keys and `notificationChannelName`.
- Tests: the `RequestNotificationPermissionUseCase` registration in `app_router_test.dart`
  and `app_router_auth_test.dart`, and the "notification permission" group in
  `app_router_test.dart`.

Docs and pages: `docs/features.md` section 6; `docs/store-release.md` section 4 and the
Firebase Cloud Messaging rows in section 2; the push row in `docs/setup.md` section 5.3;
`README.md`; the push parts of `hosting/privacy.html`.

Packages: `firebase_messaging`, `flutter_local_notifications`. Core library desugaring in
`android/app/build.gradle.kts` exists only for `flutter_local_notifications`
(`docs/tech-stack.md` section 3). Removing the packages and desugaring was not part of the
check.

### 5.5 D. Auth and profile

Remove B first.

Delete `lib/domain/auth`, `lib/data/auth`, `lib/presentation/auth`,
`lib/presentation/profile`, `lib/app/router/auth_redirect.dart`,
`lib/app/observability/crash_reporting_user_sync.dart`; under `test/` the same four
folders, `test/app/router/auth_redirect_test.dart`, `test/app/router/app_router_auth_test.dart`,
`test/app/observability/crash_reporting_user_sync_test.dart` and
`test/helpers/auth_fixtures.dart`.

Edit:

- `app/bootstrap.dart`: `getIt<AuthBloc>()` for the router and `syncCrashReportingUser`.
- `app/router/app_router.dart`: the `AuthBloc` parameter and the redirect.
- `app/router/routes.dart`: the sign-in, sign-up and reset-password routes, the Profile
  branch with its observer, and their screen names.
- `presentation/home_shell/pages/home_shell_page.dart`: the Profile destination.
- `app/di/network_module.dart`: the `backendDio` registration, which needs the
  `TokenProvider` from `data/auth`. `AuthInterceptor`, `TokenProvider` and
  `createBackendDio` stay in `data/_shared/network` as the pattern for a backend with
  sign-in.
- `domain/_shared/services/analytics_events.dart`: `login`, `sign_up`,
  `password_reset_requested`, `account_deleted`, the `method` parameter and the `password`
  value.
- ARB keys: `navProfile`, the seven `auth*`, four `signIn*`, three `signUp*`, four
  `resetPassword*` and eight `profile*` keys.
- Tests: the auth mocks and the `EmailAuthProvider` fallback value in
  `test/helpers/mocks.dart`; `app_test.dart` and `app_router_test.dart` (`createAppRouter()`
  without `AuthBloc`, the Profile tab). Two tests fail only at run time:
  `injection_test.dart` (the `backendDio` check) and `home_shell_page_test.dart` (the list
  of tabs).
- Optional: `AuthFailure` in `domain/_shared/failure.dart`, its messages and the
  `failureAuth*` keys can stay; nothing produces them any more.

Docs and pages: `docs/features.md` sections 1, 2, 4 and 7; `docs/architecture.md` sections
5.4 and 5.5; the Email Address, User ID and linked Crash Data rows in `docs/store-release.md`
section 2; the Firebase line in `CLAUDE.md`. Without sign-up, the in-app account deletion
requirement does not apply: remove `hosting/delete-account.html` and its link in the store
consoles.

Packages: `firebase_auth`.

## 6. Release

Before submitting to the stores, follow `docs/store-release.md`.

## 7. What has been verified

The script was verified on a fresh clone up to the Firebase step: dry run, rename, code
generation, analyze, import check, all tests, and the iOS build settings. On Android, with the
Google Services and Crashlytics plugins removed from that copy, the dev build ran on an
emulator. A build with configs from new Firebase projects has not been run: the first real
project closes this check.
