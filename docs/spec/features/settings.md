# Settings

Theme, language, usage data sharing, privacy policy and app info. Available to guests.
Implementation: [areas/settings.md](../areas/settings.md).

## Requirements

### Appearance

- **SET-1** Theme is chosen from a radio list: System / Light / Dark. The default is System,
  which follows the device theme.
  - GIVEN a fresh install WHEN the app starts THEN the theme follows the device
  - WHEN the user selects Dark THEN the app switches to the dark theme
- **SET-2** Language is chosen from a radio list: System / English / Українська. The default is System.
  - WHEN the user selects Українська THEN the app shows Ukrainian texts
- **SET-3** With the System language, the app uses the first device language it supports
  (English or Ukrainian), otherwise English.
  - GIVEN device languages German, Ukrainian WHEN the language preference is System THEN the
    app is in Ukrainian
  - GIVEN only unsupported device languages THEN the app is in English
- **SET-4** The first frame already uses the saved theme and language (no flicker).
  - GIVEN the user chose Dark and Ukrainian WHEN the app launches THEN the first frame is dark
    and Ukrainian
- **SET-5** A chosen value stays applied when saving it fails, and the page shows the failure message.
  - WHEN saving a new theme fails THEN the new theme stays applied and the failure message is shown

### Privacy

- **SET-6** "Share usage data" is a switch with a short explanation below it. It is a device
  setting, not an account one. Its default comes from `USAGE_DATA_SHARING_DEFAULT`
  (`true` in the starter).
  - GIVEN a fresh install WHEN the settings page opens THEN the switch shows the configured default
  - WHEN another user signs in on the same device THEN the switch keeps its value
- **SET-7** Analytics and crash reporting collect data only when the flavor's collection rule
  AND the "Share usage data" setting allow it; the rule wins. The value applies before the
  first event and on every change, without a restart.
  - GIVEN the `prod` flavor in a release build WHEN the user turns the switch off THEN
    analytics and Dart crash reports stop at once, without a restart
  - GIVEN the `dev` flavor WHEN the switch is off THEN collection stays on (the rule wins)
- **SET-8** "Share usage data" does not affect notifications: they are delivery, not data collection.
  - WHEN the switch is off THEN notifications are still received
- **SET-9** "Privacy policy" opens the page from `PRIVACY_POLICY_URL` (the prod page in both
  flavors) in the in-app browser (Custom Tabs on Android, SFSafariViewController on iOS), then
  in an external browser. If neither opens, a SnackBar shows a localized message with a
  "Copy link" action. The page is never cached by the app.
  - WHEN the user taps "Privacy policy" THEN the page opens in the in-app browser
  - WHEN the in-app browser cannot open THEN an external browser opens
  - WHEN neither opens THEN a SnackBar with "Copy link" is shown

### About

- **SET-10** The settings page shows the app version.
  - WHEN the settings page opens THEN the app version is shown
- **SET-11** In the `dev` flavor only, the page has a "Logs" entry that opens the log screen
  (`/settings/logs`, NAV-7) and a "Test crash" entry that throws an error to check crash reporting.
  - GIVEN the `dev` flavor WHEN the settings page opens THEN "Logs" and "Test crash" are shown
  - GIVEN the `prod` flavor THEN neither entry is shown

## Screens

### SCR-9 Settings

- Route: `/settings` (third tab).
- States: Appearance (SET-1, SET-2), Privacy (SET-6, SET-9), About (SET-10, SET-11); save
  failure message (SET-5); "Copy link" SnackBar (SET-9).
- Design: pending

### SCR-10 Logs

- Route: `/settings/logs`, `dev` flavor only (NAV-7, SET-11). Shows `TalkerScreen`.
- States: the log list provided by `talker_flutter`.
- Design: pending (a package screen)

## Implementation notes

- SET-7: limits of the switch and how to make collection opt-in:
  [guides/store-release.md](../../guides/store-release.md), Switching to opt-in. Mechanism:
  [areas/observability.md](../areas/observability.md), Usage data collection.

Manual: SET-8

Retired: none
