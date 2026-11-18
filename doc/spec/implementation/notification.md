# Implementation: notification

**Code:** `domain/entity/notification_message.dart`,
`domain/repository/notification_repository.dart`,
`domain/use_case/notification`, `data/notification`; wiring in
`app/notification`; the permission dialog in `presentation/_shared/widget/dialog`. Behavior:
[behavior/notification.md](../behavior/notification.md).

## Domain

- `NotificationRepository`:
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
- The permission flow (NTF-1, NTF-2) runs in the character details route builders
  (`CharacterDetailRoute` and `FavoriteDetailRoute`) in `app/router/routes.dart`:
  `ShouldAskNotificationPermissionUseCase` (false, or a failure, after any answer), then the
  dialog, then `RequestNotificationPermissionUseCase` with the answer. A dialog that could
  not be shown records nothing, so the user is asked again. Authentication is optional and
  notifications are not tied to an account, so the moment does not depend on sign-in. A new
  app replaces only this trigger in `app/router/routes.dart`.
- `app/notification` calls the other use cases: initialize, register, the registration ID
  stream, foreground messages with text (`WatchForegroundNotificationsUseCase` drops a
  data-only message), showing one, and opened messages.

## Data

- Data sources: `NotificationFcmDataSource` (`FirebaseMessaging`),
  `NotificationNotifDataSource` (`flutter_local_notifications`) and
  `NotificationPrefsDataSource`; `notification_fcm_module.dart` provides `FirebaseMessaging`
  and `notification_notif_module.dart` the plugin.
- Android foreground messages are shown with `flutter_local_notifications` on the `general`
  channel, which is also the FCM default channel in `AndroidManifest.xml`.
- The flag `notification.permission_requested` (`SharedPreferencesAsync`) is set when the
  dialog has been answered, before the system request.

## App wiring

- Background handler: top-level function in `app/notification/background_handler.dart`; it
  must not access Hive.
- FCM copies `data` to the launch intent, and `FlutterActivity` reads its `route` extra as the
  platform default route. The router ignores that default (`overridePlatformDefaultLocation`),
  so the app always starts on `/character-list` and a route from a notification only goes
  through the check in NTF-7.

## Registration

- FCM runs in FID mode: the app uses
  `register()` and `onRegistered` from `firebase_messaging` with
  `firebase_messaging_installation_id_enabled` in `AndroidManifest.xml`. `getToken` and
  `onTokenRefresh` are deprecated and not used.
- The FID is logged with Talker (no backend to register it yet).
- What a backend and a third-party push service need:
  [guide/store-release.md](../../guide/store-release.md), Push notifications.
