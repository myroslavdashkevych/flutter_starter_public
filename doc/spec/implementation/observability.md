# Implementation: observability

**Code:** `app/observability`, `shared/logging`, `domain/_shared/service`,
`domain/use_case/observability`,
`domain/use_case/settings/set_usage_data_collection_use_case.dart`, `data/_shared/service`,
`app/router/screen_view_observer.dart`, `app/bootstrap.dart`.
Behavior: [behavior/observability.md](../behavior/observability.md).

How logs, crash reports, analytics and usage data collection work. The rules they follow:
[architecture.md](../architecture.md), Logging and errors.

## Logging

- `createBlocObserver` (`app/observability/bloc_logging.dart`) builds the
  `TalkerBlocObserver` that `bootstrap.dart` installs. It logs errors in every flavor, and
  outside `prod` also events with their `toString()` (OBS-7) and transitions (OBS-6). The Dio
  logger: [network.md](network.md), Clients.

## Crash reporting

- `FlutterError.onError` and `PlatformDispatcher.instance.onError`, installed from
  `bootstrap.dart`, report fatal errors through `CrashReportingService` directly: error
  reporting is infrastructure, like DI ([architecture.md](../architecture.md), Data flow).
- `syncCrashReportingUser` in `app/observability` follows `WatchAuthStateUseCase` and sets
  the user id of crash reports through `SetCrashReportingUserUseCase` (OBS-2).
- `CrashReportingTalkerObserver` in `app` forwards `talker.handle` as non-fatal reports. It
  does not forward `talker.error` or other logs, because `TalkerBlocObserver` logs a Bloc
  handler error with `talker.error` and Bloc then rethrows it to
  `PlatformDispatcher.onError`, which already reports it.

## Usage data collection

- `AnalyticsService` and `CrashReportingService` both have `setCollectionEnabled`, which
  `SetUsageDataCollectionUseCase` calls together. `syncUsageDataCollection` in
  `app/observability`, started from `bootstrap.dart`, calls that use case with
  `Flavor.collectsUsageData` AND the "Share usage data" setting, at startup and on every
  change of the setting. The rule wins: always on in the `dev` flavor; in `prod` only in
  non-debug builds.
- The native SDKs collect by default until that call on the very first launch; later
  launches start with the stored value, which the SDKs persist.
- Crashlytics applies `false` only from the next run, so `FirebaseCrashReportingService`
  drops errors itself while collection is off and deletes the reports stored on the device.
  What this means for users and for the privacy policy:
  [guide/store-release.md](../../guide/store-release.md), Switching to opt-in.

## Screen views

- `ScreenViewObserver` (`app/router`) is attached to the root navigator and to every shell
  branch navigator, each with its own instance. It sends `screen_view` through
  `TrackScreenViewUseCase` and `AnalyticsService`, so tests never reach Firebase, with the
  route's `name` ([security.md](../security.md), Personal data). Only `PageRoute`s count: dialogs, bottom sheets and popups do not. It reports
  `didPush`, `didReplace` and, on `didPop`, the screen returned to.
  `FirebaseAnalyticsObserver` is not used.
- go_router forwards events of shell navigators to the root observers, so an observer ignores
  routes of other navigators. Switching tabs causes no navigator event: the shell route
  builder reports the top route of the selected branch. A branch shown for the first time
  reports through its observer. The shell's own route has no name, so closing an auth page
  reports the current tab's top route.
