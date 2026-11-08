# Area: observability

**Areas:** `app/observability`, `shared/logging`, `domain/_shared/services`,
`data/_shared/services`, `app/router/screen_view_observer.dart`, `app/bootstrap.dart`.
Behavior: [features/observability.md](../features/observability.md).

How logs, crash reports, analytics and usage data collection work. The rules they follow:
[architecture.md](../architecture.md), Logging and errors.

## Logging

- `TalkerBlocObserver` is wired in `app`. The Dio logger: [network.md](network.md), Clients.

## Crash reporting

- `FlutterError.onError` and `PlatformDispatcher.instance.onError`, installed from
  `bootstrap.dart`, report fatal errors through `CrashReportingService`.
- `CrashReportingTalkerObserver` in `app` forwards `talker.handle` as non-fatal reports. It
  does not forward `talker.error` or other logs, because `TalkerBlocObserver` logs a Bloc
  handler error with `talker.error` and Bloc then rethrows it to
  `PlatformDispatcher.onError`, which already reports it.

## Usage data collection

- `AnalyticsService` and `CrashReportingService` both have `setCollectionEnabled`.
  `syncUsageDataCollection` in `app/observability`, started from `bootstrap.dart`, calls them
  with `Flavor.collectsUsageData` AND the "Share usage data" setting, at startup and on every
  change of the setting. The rule wins: always on in the `dev` flavor; in `prod` only in
  non-debug builds ([ADR-009](../../decisions/ADR-009-usage-data-collection.md)).
- The native SDKs collect by default until that call on the very first launch; later
  launches start with the stored value, which the SDKs persist.
- Crashlytics applies `false` only from the next run, so `FirebaseCrashReportingService`
  drops errors itself while collection is off and deletes the reports stored on the device.
  What this means for users and for the privacy policy:
  [guides/store-release.md](../../guides/store-release.md), Switching to opt-in.

## Screen views

- `ScreenViewObserver` (`app/router`) is attached to the root navigator and to every shell
  branch navigator, each with its own instance. It sends `screen_view` through
  `AnalyticsService`, so tests never reach Firebase, with the route's `name`, which carries no
  ids. Only `PageRoute`s count: dialogs, bottom sheets and popups do not. It reports
  `didPush`, `didReplace` and, on `didPop`, the screen returned to.
  `FirebaseAnalyticsObserver` is not used (ADR-003).
- go_router forwards events of shell navigators to the root observers, so an observer ignores
  routes of other navigators. Switching tabs causes no navigator event: the shell route
  builder reports the top route of the selected branch. A branch shown for the first time
  reports through its observer. The shell's own route has no name, so closing an auth page
  reports the current tab's top route.
