# Observability

Crash reporting, analytics and logs. Implementation:
[areas/observability.md](../areas/observability.md).

## Requirements

- **OBS-1** Crashlytics and Analytics run in both flavors; collection follows the rule in SET-7.
  - GIVEN collection is allowed WHEN a Dart error is reported THEN it reaches Crashlytics in
    either flavor
- **OBS-2** Crash reports carry the Firebase UID after sign-in; it is cleared on sign-out.
  - WHEN a user signs in THEN later crash reports carry their UID
  - WHEN the user signs out THEN later crash reports carry no UID
- **OBS-3** `screen_view` is sent with the route name on a push, a replace, a return to a
  screen, and a tab selection. Tapping the active tab on its root sends nothing.
  - WHEN the user opens item details THEN `screen_view` is sent with the details route name
  - WHEN the user goes back to the list THEN `screen_view` is sent for the list
  - WHEN the user selects another tab THEN `screen_view` is sent for that tab's top route
  - WHEN the user taps the active tab on its root THEN nothing is sent
- **OBS-4** Dialogs, bottom sheets and popups are not screens and send no `screen_view`.
  - WHEN a dialog opens THEN no `screen_view` is sent
- **OBS-5** Feature events are listed in each feature file (AUTH-8, ITM-17, ITM-18, PRF-8,
  FAV-11) and are sent through `AnalyticsService`.
  - WHEN a feature event fires THEN it goes through `AnalyticsService`
- **OBS-6** Talker logs HTTP traffic, and BLoC transitions outside `prod`. The log screen is in
  `dev` only (NAV-7, SET-11).
  - GIVEN the `dev` flavor WHEN an HTTP request runs THEN it appears in the log screen
  - GIVEN the `prod` flavor THEN BLoC transitions are not logged (errors only)

Retired: none
