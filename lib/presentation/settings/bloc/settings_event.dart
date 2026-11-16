import 'package:flutter_starter/domain/entity/app_settings.dart';

/// All settings events share one sequential handler, so changes are saved in
/// the order they were made (SET-12).
sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

final class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged(this.preference);

  final ThemePreference preference;
}

final class SettingsLocaleChanged extends SettingsEvent {
  const SettingsLocaleChanged(this.preference);

  final LocalePreference preference;
}

final class SettingsUsageDataSharingChanged extends SettingsEvent {
  const SettingsUsageDataSharingChanged(this.enabled);

  final bool enabled;
}
