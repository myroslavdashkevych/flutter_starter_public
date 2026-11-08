# Area: settings

**Areas:** `domain/settings`, `data/settings`, `presentation/settings`. Behavior:
[features/settings.md](../features/settings.md).

## Domain

- `AppSettings` entity: `themePreference` (`system`, `light`, `dark`), `localePreference`
  (`system`, `en`, `uk`), `usageDataSharing`.
- Default: `system` for both preferences. `usageDataSharing` defaults to
  `USAGE_DATA_SHARING_DEFAULT` from `config/*.json` (`true` in the starter).
- `SettingsRepository`:
  - `Future<AppSettings> load()`
  - `Future<Result<void>> save(AppSettings settings)`

## Data

- `SharedPreferencesAsync`, keys `settings.theme` and `settings.locale`, values are enum
  names. Unknown or missing values fall back to `system`.
- Key `settings.usage_data_sharing`, a boolean. A missing value, or a storage error, falls
  back to the default from the config.

## Presentation and wiring

- `SettingsCubit` (global singleton) holds `AppSettings` and the last save failure;
  `app.dart` maps the settings to `ThemeMode` and `Locale?`.
- Settings are loaded in `bootstrap.dart` **before** `runApp` (SET-4).
- Privacy policy: `app/links/open_link.dart` holds the `url_launcher` calls, and the page
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
