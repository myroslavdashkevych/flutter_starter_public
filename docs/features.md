# Features

Functional specification of the demo app. Every user-facing string comes from
ARB files in English and Ukrainian.

## 1. Navigation map

```
/sign-in                     # pushed over the shell from the Profile tab
/sign-up                     # pushed from /sign-in
/reset-password              # pushed from /sign-in
StatefulShellRoute (bottom navigation, presentation/home_shell)
  ├─ /items                  # items_list, the initial location
  │    └─ /items/:id         # item_details
  ├─ /profile                # profile: guest or account view
  │    └─ /profile/favorites       # favorites
  │         └─ /profile/favorites/:id  # item_details, the same page as /items/:id
  └─ /settings               # settings
         └─ /settings/logs   # TalkerScreen, dev flavor only
```

Bottom navigation tabs, in order: **Items**, **Profile**, **Settings**.
Each tab keeps its own navigation stack.

Authentication is optional: Items, item details and Settings work without signing in.

Redirect rule (from `AuthBloc` state): signed in → auth routes redirect to `/profile`.
There is no other redirect, and no route requires a signed-in user: a guest who
reaches `/profile/favorites` sees a sign-in prompt on that page.

After a successful sign-in or sign-up the route builder calls
`ProfileRoute().go(context)`, which removes the whole auth stack and keeps the other
tabs' stacks. The redirect cannot do this: go_router does not see a pushed route in
the location it passes to a redirect. Native deep links (Android intent filters, iOS
URL schemes) are not configured.

## 2. Auth

**Areas:** `domain/auth`, `data/auth`, `presentation/auth`.

### Domain
- `AppUser` entity: `id`, `email` (nullable: future providers may not supply one).
- `AuthRepository`:
  - `Stream<AppUser?> authStateChanges()`
  - `Future<Result<AppUser>> signIn({email, password})`
  - `Future<Result<AppUser>> signUp({email, password})`
  - `Future<Result<void>> sendPasswordReset({email})`
  - `Future<Result<void>> signOut()`
  - `Future<Result<void>> reauthenticate({password})`
  - `Future<Result<void>> deleteAccount()`
- The contract is provider-agnostic so Google and Apple sign-in can be added later
  without changes to domain or features.

### Data
- Firebase Auth implementation.
- `FirebaseAuthException.code` → `AuthFailure(reason)`:
  `invalidCredentials`, `emailAlreadyInUse`, `weakPassword`, `invalidEmail`,
  `userDisabled`, `tooManyRequests`, `requiresRecentLogin`, `network`, `unknown`.
- With email enumeration protection (default for new Firebase projects), wrong
  email and wrong password both arrive as `invalid-credential` → `invalidCredentials`.
- Implements `TokenProvider` for `backendDio`.

### Features
- `AuthBloc` (global singleton): listens to `authStateChanges`; states:
  `unknown`, `authenticated(user)`, `unauthenticated`. It only reacts: sign-out is
  called by `ProfileCubit` through `AuthRepository`.
- `SignInCubit`, `SignUpCubit`, `ResetPasswordCubit` with form validation:
  - email: non-empty, basic format;
  - password: at least 6 characters (Firebase default policy);
  - sign-up: password confirmation must match.
- Pages show loading state, disable submit while loading, and show a localized
  error for each `AuthFailureReason`.
- Reset password: on success shows "check your email" regardless of whether the
  address exists (`user-not-found` is treated as success).

### Analytics events
`login`, `sign_up` (standard Firebase event names), `password_reset_requested`.

## 3. Items (list and details)

**Areas:** `domain/items`, `data/items`, `presentation/items_list`, `presentation/item_details`.

### Source
Rick and Morty API, characters endpoint, via `publicDio` (no auth header).
- List: `GET /character?page={page}&name={query}`; 20 per page;
  `info.next == null` means the last page.
- Details: `GET /character/{id}`.
- An empty search result is returned by the API as HTTP 404 with an error body
  (`{"error":"There is nothing here"}`, verified). A page past the last one answers
  the same way. `data/items` maps a list 404 to an empty `Paginated` result, **not**
  to a failure, and does not cache it. A 404 for details stays `NotFoundFailure`,
  even with a stale cache, because the item no longer exists.

### Domain
- `Item` entity: `id`, `name`, `imageUrl`, `status` (`ItemStatus`: alive, dead,
  unknown), `species`, `gender`, `originName`, `locationName`, `episodeCount`.
  The `items` area is a demo and is expected to be replaced in real projects.
- `ItemsRepository`:
  - `Future<Result<Paginated<Item>>> getPage({required int page, String? query, bool forceRefresh = false})`
  - `Future<Result<Item>> getById(int id)`

### Data
- `ItemsApi` (retrofit), `CharacterDto`, `PageInfoDto`, `CharactersPageDto` (the list
  response: `info` and `results`), mapper `toEntity()`.
- Cache in hive_ce `LazyBox` (`items_cache`); this is the starter's example of a cache
  (`docs/architecture.md` section 5.6):
  - key: `list:page={page}:q={query}` and `item:{id}`;
  - value: a JSON **string** of the envelope
    `{ "schemaVersion": 1, "fetchedAt": <iso8601>, "data": <dto.toJson()> }`;
  - TTL from `ITEMS_CACHE_TTL_MINUTES` (default 30);
  - writing a page also writes `item:{id}` for each of its items, so details open
    offline for everything in a cached list;
  - the box is opened on first use; parallel first calls share one opening `Future`.
- A record with a different `schemaVersion` or that fails to decode is treated as
  missing (logged, then refetched). It never surfaces as a failure.
- After the first frame of every launch, records older than 90 days, with another
  `schemaVersion` or with an unreadable envelope are deleted. Until then a record can
  still be shown offline.
- Strategy:
  1. Fresh cache hit and not `forceRefresh` → return cache.
  2. Otherwise request the network; on success write to cache and return.
  3. On a network or server (5xx) failure → return stale cache if present, else the
     failure. So a refresh without a connection shows the cached data, not an error.

### Use cases (reference example)
- `domain/items/usecases/get_items_page_use_case.dart`
- `domain/items/usecases/get_item_details_use_case.dart`

### items_list
- Search field above the list: server-side search by name, debounce 400 ms;
  a new query restarts pagination (`restartable` transformer).
- Infinite scroll: load the next page when 80% of the list is scrolled.
- Pull-to-refresh: `forceRefresh: true` for page 1. When it fails, the list stays and
  a one-time `SnackBar` shows the failure message.
- A new search or a refresh makes older requests obsolete: a result that arrives
  afterwards is dropped (checked against a generation counter in the state).
- States: initial loading, list, empty (no results / nothing loaded), error with
  retry, loading-more indicator, error while loading more (inline retry).
- Each tile: image, name, species and status. Tapping opens `/items/:id`.
- The API host limits bursts of requests (HTTP 429, `retry-after: 10`), which fast
  scrolling reaches with an empty image cache. A failed image stays blank and is
  retried up to 3 times, 10 seconds apart; only then it shows an error icon.

### item_details
- Shows all `Item` fields and a large image.
- Error state with retry.

Both features use the same `ItemsRepository` from `domain/items`: this is the
reference example of one domain area serving several features.

### Analytics events
`search` (standard event, parameter `search_term`), sent for a non-empty query after
the debounce; `select_content` when an item is opened, not on a retry.

## 4. Profile

**Areas:** `domain/auth`; feature `presentation/profile`.

### Feature
- `ProfileCubit` reads the current user from `AuthRepository.authStateChanges()`.
  It does not import `presentation/auth`. Sign-out and account deletion switch the
  page to the guest view without navigation.
- Profile page:
  - Auth state unknown: an empty body, so the sign-in button does not flash.
  - Guest: a short explanation and **Sign in**, which opens `/sign-in`.
  - Signed in:
    - Email.
    - **Favorites**: opens `/profile/favorites` (section 9).
    - **Sign out**: confirmation dialog → `AuthRepository.signOut()`.
    - **Delete account**: warning dialog explaining that the action is permanent →
      password field → `DeleteAccountUseCase`.
- Delete account errors: wrong password (`invalidCredentials`), network,
  too many requests; each shown as a localized message, the user stays signed in.

### Use case: `domain/auth/usecases/delete_account_use_case.dart`
Encodes a business rule (deletion only after a fresh password check):
1. `AuthRepository.reauthenticate(password)`. Firebase requires a recent sign-in
   for deletion; re-authenticating first avoids the `requires-recent-login` error.
   If it fails, stop and return the failure.
2. `AuthRepository.deleteAccount()`. The user id is read before this step, because
   deletion ends the session.
3. `FavoritesRepository.clearForUser(uid)`. A failure is logged by the repository and
   does not fail the use case: the account is already gone. The orphaned box stays on
   the device and is not retried.

If a future feature stores user-specific local data, its cleanup is added to this
use case.

### Scope note
The starter has no backend, so deletion removes the Firebase Auth account and the
local favorites only. A real project with a backend must also delete server-side user
data (a backend endpoint or a Cloud Function on user deletion). Apple App Store
and Google Play require in-app account deletion for apps that allow sign-up.

### Analytics events
`account_deleted`.

## 5. Settings

**Areas:** `domain/settings`, `data/settings`, `presentation/settings`.

### Domain
- `AppSettings` entity: `themePreference` (`system`, `light`, `dark`),
  `localePreference` (`system`, `en`, `uk`), `usageDataSharing`.
- Default: `system` for both preferences. `usageDataSharing` defaults to
  `USAGE_DATA_SHARING_DEFAULT` from `config/*.json` (`true` in the starter).
- `SettingsRepository`:
  - `Future<AppSettings> load()`
  - `Future<Result<void>> save(AppSettings settings)`

### Data
- `SharedPreferencesAsync`, keys `settings.theme` and `settings.locale`,
  values are enum names. Unknown or missing values fall back to `system`.
- Key `settings.usage_data_sharing`, a boolean. A missing value, or a storage error,
  falls back to the default from the config.

### Feature
- `SettingsCubit` (global singleton) holds `AppSettings` and the last save failure;
  `app.dart` maps the settings to `ThemeMode` and `Locale?`. A new value stays
  applied when saving fails, and the page shows the failure message.
- Settings are loaded in `bootstrap.dart` **before** `runApp`, so the first frame
  already uses the right theme and language (no flicker).
- Settings page, available to guests:
  - **Appearance**
    - Theme: radio list: System / Light / Dark.
    - Language: radio list: System / English / Українська.
  - **Privacy**
    - "Share usage data": a switch with a short explanation below it. It is a device
      setting, not an account one.
    - "Privacy policy": opens the page from `PRIVACY_POLICY_URL` (the prod page in both
      flavors) in the in-app browser (Custom Tabs on Android, SFSafariViewController on
      iOS), then in an external browser. If neither opens, a SnackBar shows a localized
      message with a "Copy link" action. The page is never cached by the app.
      `app/links/open_link.dart` holds the `url_launcher` calls, and the page receives a
      callback, so `presentation` does not depend on the plugin.
  - **About**
    - App version: `bootstrap.dart` reads it with `package_info_plus` and passes it
      to the page as a string, so `presentation` does not depend on the plugin.
    - Dev flavor only: "Logs" entry opening `TalkerScreen`, and "Test crash", which throws
      an error to check crash reporting.

### Usage data sharing
- Effective value = the collection rule AND the setting; the rule wins. It applies before
  the first event and on every change, without a restart. Mechanism:
  `docs/architecture.md` 5.10.
- It does not affect notifications: they are delivery, not data collection.
- Limits, and how to switch to opt-in: `docs/store-release.md` section 3.

### Locale resolution
- `supportedLocales`: `en` (first), `uk`.
- `localePreference == system` → `MaterialApp.locale = null` and a
  `localeListResolutionCallback` that returns the first device locale whose
  language code is supported, otherwise `en`.
- Explicit preference → `MaterialApp.locale = Locale(code)`.

### Theme
- Material 3, `ColorScheme.fromSeed`, light and dark themes in
  `presentation/_shared/theme`.
- `system` → `ThemeMode.system`.

## 6. Notifications

**Areas:** `domain/notifications`, `data/notifications`; wiring in `app`.

- `NotificationsRepository`:
  - `Future<Result<void>> initialize({required String channelName})`
  - `Future<Result<void>> register()`
  - `Stream<String> registrationIdChanges()` (the Firebase Installation ID, FID)
  - `Future<Result<bool>> wasPermissionAsked()`, `Future<Result<void>> markPermissionAsked()`
  - `Future<Result<bool>> requestPermission()`
  - `Stream<NotificationMessage> foregroundMessages()`
  - `Future<Result<void>> showForeground(NotificationMessage message)`
  - `Stream<NotificationMessage> openedMessages()` (taps, including the message
    that launched the app)
- `NotificationMessage`: `title`, `body`, `route` (optional deep link).
- Android foreground messages are shown with `flutter_local_notifications` on the
  `general` channel, which is also the FCM default channel in `AndroidManifest.xml`.
  Its name is localized by the device language, as the system settings show it.
- Background handler: top-level function in `app/notifications/background_handler.dart`;
  it must not access Hive.
- Tapping a notification with `data.route` (for example `/items/1`) navigates there. A
  route comes from outside the app: anything but an existing in-app location, or an
  `id` that is not a number, is logged and ignored.
- FCM copies `data` to the launch intent, and `FlutterActivity` reads its `route` extra
  as the platform default route. The router ignores that default
  (`overridePlatformDefaultLocation`), so the app always starts on `/items` and a route
  from a notification only goes through the check above.
- Android may show only the splash background, without the logo, when a notification
  launches the app. This is system behavior; a launch from the home screen shows the logo.
- iOS: code is present; delivery requires an APNs key, which is not configured. Until
  then `register()` fails on every launch, which is logged as a warning and not sent
  to Crashlytics.

### Permission
- Authentication is optional and notifications are not tied to an account, so the
  moment does not depend on sign-in. `RequestNotificationPermissionUseCase` runs after
  the first opened item loads, for guests and signed-in users alike. A failed load
  and a retry do not trigger it. A new app replaces only the trigger in
  `app/router/routes.dart`.
- Asked once per install: first an own dialog with **Allow** and **Not now**, and the
  system request only after **Allow**. iOS shows the system request a single time, so
  **Not now** must not use it up.
- The flag `notifications.permission_requested` (`SharedPreferencesAsync`) is set when
  the dialog has been answered, before the system request. Dismissing the dialog
  counts as **Not now**.

### Registration
- The app uses `register()` and `onRegistered` from `firebase_messaging` with
  `firebase_messaging_installation_id_enabled` in `AndroidManifest.xml`. `getToken` and
  `onTokenRefresh` are deprecated and not used.
- The FID is logged with Talker (no backend to register it yet).
- A backend must send with the target `fid`. Check any third-party push service for
  FID support before adopting it (also in `docs/store-release.md` section 4).

## 7. Observability

- Crashlytics and Analytics in both flavors; collection follows the rule in
  `docs/architecture.md` 5.10. Crash reports carry the Firebase UID after sign-in; it is
  cleared on sign-out.
- Screen views: `screen_view` with the route name on a push, a replace, a return to a
  screen, and a tab selection. Tapping the active tab on its root sends nothing.
  Dialogs, bottom sheets and popups are not screens.
- Events are listed in each feature section and sent through `AnalyticsService`.
- Talker logs HTTP traffic, and BLoC transitions outside `prod`; `TalkerScreen` in dev
  only. `/settings/logs` redirects to `/settings` in `prod`.

## 8. Native splash

- The operating system shows the logo centered on the theme's `surface` color until
  Flutter draws its first frame, so a cold start has no white frame.
- Logo and background follow the **system** theme, not the theme chosen in Settings:
  a native splash is shown before any Dart code runs, so it cannot read that
  preference. With an explicit theme that differs from the system one, the background
  changes when the first app screen appears.
- Android 12+ shows the logo through the system splash API, which clips it to a circle.
- Configuration and regeneration: `docs/setup.md` section 10.

## 9. Favorites

**Areas:** `domain/favorites`, `data/favorites`, `presentation/favorites`;
the toggle lives in `presentation/_shared/favorites`.

Favorites belong to signed-in users. A guest sees no toggles and no **Favorites**
entry on the profile. Changes show at once on every screen, through streams.

### Domain
- Uses the `Item` entity from `domain/items`.
- `FavoritesRepository`:
  - `Stream<List<Item>> watchAll()`: newest first; empty for a guest
  - `Stream<bool> watchIsFavorite(int id)`
  - `Future<Result<bool>> toggle(Item item)`: returns the new state
  - `Future<Result<void>> clearForUser(String uid)`: deletes everything stored for
    that user, signed in or not
- `domain/favorites/usecases/toggle_favorite_use_case.dart`. It only delegates for now;
  the analytics events below are added to it.

### Data
- hive_ce `LazyBox` per user, `favorites_<uid in hex>`. Hive lower-cases box names and
  user ids are case-sensitive, so the id is stored in hex.
- Key: the item id. Value: a JSON **string** of the envelope
  `{ "schemaVersion": 1, "addedAt": <iso8601>, "data": <dto.toJson()> }`.
- `FavoriteItemDto` is a snapshot of `Item`. This is user data, not a cache
  (`docs/architecture.md` section 5.6): it never expires and is never deleted
  automatically, only when the user removes a favorite or deletes the account. DTO
  changes must stay backward compatible or ship a migration.
- A record with another `schemaVersion` or that fails to decode is skipped and logged,
  and stays in the box so a later version can migrate it. Toggling that item overwrites it.
- The repository follows `AuthRepository.authStateChanges()`. On a user change it hides
  the previous favorites at once, closes the old box and opens the new one; after
  sign-out the state is empty. Storage operations run one at a time.
- If the box cannot be opened, the failure is logged and the list is empty; the next
  `toggle` tries to read it again and returns `CacheFailure` if that fails too.

### Toggle
- `FavoriteToggleCubit` and `FavoriteToggle` in `presentation/_shared/favorites`, shown
  on each item list tile and in the item details app bar. Hidden from a guest. A failed
  toggle shows a `SnackBar`.

### favorites
- `FavoritesCubit` follows the auth state and `watchAll()`.
- Page states:
  - Auth state or favorites not known yet: a progress indicator.
  - Guest: "Sign in to save favorites" and **Sign in**, which opens `/sign-in`. After
    signing in the user lands on `/profile`, like every sign-in.
  - No favorites: a hint.
  - List, newest first, from the stored snapshots. Tapping opens
    `/profile/favorites/:id`; removing the mark removes the tile at once.

### Details of a favorite
`/profile/favorites/:id` is the `item_details` page and loads through `ItemsRepository`,
not from the snapshot.
- `NotFoundFailure`: the message without a retry, and **Remove from favorites**, which
  removes the favorite and returns to the list.
- Any other failure: the usual retry.

`/items/:id` always shows the retry.

### Analytics events
`add_to_wishlist` (standard event name) and `remove_from_wishlist` (custom event), with
`item_id`, sent by `ToggleFavoriteUseCase` when a toggle succeeds.
