# Notifications

Push notifications through Firebase Cloud Messaging. Not tied to an account.
Implementation: [areas/notifications.md](../areas/notifications.md).

## Requirements

### Permission

- **NTF-1** The app asks for notification permission after the first opened item loads, for
  guests and signed-in users alike. A failed load and a retry do not trigger it.
  - GIVEN permission was never asked WHEN item details load for the first time THEN the
    permission dialog is shown
  - WHEN item details fail to load, or the user taps retry THEN the dialog is not shown
- **NTF-2** Permission is asked once per install: first an own dialog with **Allow** and
  **Not now**, and the system request only after **Allow**. Dismissing the dialog counts as
  **Not now**.
  - WHEN the user taps **Allow** THEN the system permission request is shown
  - WHEN the user taps **Not now** or dismisses the dialog THEN no system request is shown
  - GIVEN the dialog was answered once WHEN another item loads THEN the dialog is not shown again
- **NTF-3** **Not now** must not use up the system request: iOS shows it a single time.
  - WHEN the user taps **Not now** THEN the system request has not been shown and stays unused

### Delivery

- **NTF-4** On Android, a message received while the app is in the foreground is shown as a
  notification on the `general` channel. The channel name is localized by the device language,
  as the system settings show it.
  - GIVEN the app is in the foreground on Android WHEN a message arrives THEN a notification is
    shown on the `general` channel
- **NTF-5** On iOS the code is present, but delivery needs an APNs key, which is not configured. Until then registration
  fails on every launch; this is logged as a warning and not sent to Crashlytics.
  - GIVEN iOS without an APNs key WHEN the app launches THEN registration fails, a warning is
    logged and no crash report is sent

### Taps

- **NTF-6** Tapping a notification with `data.route` (for example `/items/1`) navigates there.
  This includes the message that launched the app.
  - WHEN the user taps a notification with `route: /items/1` THEN item 1 opens
  - GIVEN the app is not running WHEN a tap on such a notification launches it THEN the app
    starts on `/items` and then navigates to the route
- **NTF-7** A route that is not an existing in-app location, or has an `id` that is not a
  number, is logged and ignored.
  - WHEN a notification carries `route: /unknown` THEN nothing happens apart from a log entry
  - WHEN it carries `route: /items/abc` THEN nothing happens apart from a log entry
- **NTF-8** On Android, a launch from a notification may show only the splash background,
  without the logo. This is system behavior; a launch from the home screen shows the logo.
  - WHEN a notification launches the app on Android THEN the splash may show without the logo

Notifications are not affected by the "Share usage data" switch (SET-8).

## Dialogs

- **Notification permission dialog** (`presentation/_shared/widgets/dialog`): **Allow** and
  **Not now** (NTF-2). Design: pending

## Implementation notes

- NTF-1: a new app replaces only the trigger in `app/router/routes.dart`.
- NTF-6: FCM copies `data` to the launch intent, and `FlutterActivity` reads its `route` extra
  as the platform default route. The router ignores that default
  (`overridePlatformDefaultLocation`), so the app always starts on `/items` and a route from a
  notification only goes through the check in NTF-7.

Manual: NTF-8

Retired: none
