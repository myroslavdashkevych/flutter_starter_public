# Implementation: settings

**Code:** `domain/entity/app_settings.dart`, `domain/repository/settings_repository.dart`,
`domain/use_case/settings` (usage data collection:
[observability.md](observability.md)), `data/settings`, `presentation/settings`. Behavior:
[behavior/settings.md](../behavior/settings.md).

## Domain

- `AppSettings` entity: `themePreference` (`system`, `light`, `dark`), `localePreference`
  (`system`, `en`, `uk`), `usageDataSharing`.
- Default: `system` for both preferences. `usageDataSharing` defaults to
  `USAGE_DATA_SHARING_DEFAULT` from `config/*.json` (`true` in the starter).
- `SettingsRepository`:
  - `Future<Result<AppSettings>> load()` never fails: unknown or missing values and a storage
    error (logged) fall back to the defaults
  - `Future<Result<void>> save(AppSettings settings)`
- `LoadSettingsUseCase` and `SaveSettingsUseCase` pass the result of the repository through.
  The config default reaches the repository under `usageDataSharingDefaultName`, declared in
  `SettingsRepositoryImpl`.

## Data

- `SettingsPrefsDataSource` (`SharedPreferencesAsync`), keys `settings.theme` and
  `settings.locale`, values are enum names. Unknown or missing values fall back to `system`.
- Key `settings.usage_data_sharing`, a boolean. Only `SettingsRepositoryImpl` applies the
  default from the config (SET-6): when nothing is stored, and on a storage error, which it
  logs (theme and locale are then `system`).

## Presentation and wiring

- `SettingsBloc` (global singleton) loads and saves through `LoadSettingsUseCase` and
  `SaveSettingsUseCase` and holds `AppSettings`, the last save failure and
  `isLoaded`; `app.dart` maps the settings to `ThemeMode` and `Locale?`. All its events share
  one `sequential` handler, so saves run in the order of the changes (SET-12).
- Settings are loaded in `bootstrap.dart` **before** `runApp` (SET-4): it adds the load event
  and waits for `isLoaded`, not for the next state, because Bloc skips a state equal to the
  current one (stored settings equal to the defaults).
- Privacy policy: `app/link/open_link.dart` holds the `url_launcher` calls, and the page
  receives a callback, so `presentation` does not depend on the plugin.
- App version: `bootstrap.dart` reads it with `package_info_plus` and passes it to the page as
  a string, so `presentation` does not depend on the plugin.
- Usage data sharing is applied by `syncUsageDataCollection`
  ([observability.md](observability.md), Usage data collection).

## Locale resolution

- `supportedLocales`: `en` (first), `uk`.
- `localePreference == system` → `MaterialApp.locale = null` and a
  `localeListResolutionCallback` that returns the first device locale whose language code is
  supported, otherwise `en`.
- Explicit preference → `MaterialApp.locale = Locale(code)`.

## Theme

- Material 3, `ColorScheme.fromSeed`, light and dark themes in `presentation/_shared/theme`.
- `system` → `ThemeMode.system`.
