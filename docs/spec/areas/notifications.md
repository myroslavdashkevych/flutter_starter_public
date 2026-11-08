# Area: notifications

**Areas:** `domain/notifications`, `data/notifications`; wiring in `app/notifications`; the permission dialog in
`presentation/_shared/widgets/dialog`. Behavior:
[features/notifications.md](../features/notifications.md).

## Domain

- `NotificationsRepository`:
  - `Future<Result<void>> initialize({required String channelName})`
  - `Future<Result<void>> register()`
  - `Stream<String> registrationIdChanges()` (the Firebase Installation ID, FID)
  - `Future<Result<bool>> wasPermissionAsked()`, `Future<Result<void>> markPermissionAsked()`
  - `Future<Result<bool>> requestPermission()`
  - `Stream<NotificationMessage> foregroundMessages()`
  - `Future<Result<void>> showForeground(NotificationMessage message)`
  - `Stream<NotificationMessage> openedMessages()` (taps, including the message that launched
    the app)
- `NotificationMessage`: `title`, `body`, `route` (optional deep link).
- `RequestNotificationPermissionUseCase` runs the permission flow (NTF-1, NTF-2). Authentication
  is optional and notifications are not tied to an account, so the moment does not depend on
  sign-in. It is triggered from the item details route builders (`ItemDetailsRoute` and
  `FavoriteDetailsRoute`) in `app/router/routes.dart`.

## Data

- Android foreground messages are shown with `flutter_local_notifications` on the `general`
  channel, which is also the FCM default channel in `AndroidManifest.xml`.
- The flag `notifications.permission_requested` (`SharedPreferencesAsync`) is set when the
  dialog has been answered, before the system request.

## App wiring

- Background handler: top-level function in `app/notifications/background_handler.dart`; it
  must not access Hive.
- FCM copies `data` to the launch intent, and `FlutterActivity` reads its `route` extra as the
  platform default route. The router ignores that default (`overridePlatformDefaultLocation`).

## Registration

- FCM runs in FID mode ([ADR-010](../../decisions/ADR-010-fcm-fid-mode.md)): the app uses
  `register()` and `onRegistered` from `firebase_messaging` with
  `firebase_messaging_installation_id_enabled` in `AndroidManifest.xml`. `getToken` and
  `onTokenRefresh` are deprecated and not used.
- The FID is logged with Talker (no backend to register it yet).
- A backend must send with the target `fid`. Check any third-party push service for FID
  support before adopting it (also in [guides/store-release.md](../../guides/store-release.md),
  Push notifications).
