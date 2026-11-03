import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum ThemePreference { system, light, dark }

enum LocalePreference { system, en, uk }

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemePreference.system) ThemePreference themePreference,
    @Default(LocalePreference.system) LocalePreference localePreference,
    @Default(true) bool usageDataSharing,
  }) = _AppSettings;
}
