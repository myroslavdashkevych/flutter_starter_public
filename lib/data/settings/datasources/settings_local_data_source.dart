import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._preferences);

  static const themeKey = 'settings.theme';
  static const localeKey = 'settings.locale';
  static const usageDataSharingKey = 'settings.usage_data_sharing';

  final SharedPreferencesAsync _preferences;

  Future<String?> readTheme() => _preferences.getString(themeKey);

  Future<String?> readLocale() => _preferences.getString(localeKey);

  Future<bool?> readUsageDataSharing() =>
      _preferences.getBool(usageDataSharingKey);

  Future<void> writeTheme(String value) =>
      _preferences.setString(themeKey, value);

  Future<void> writeLocale(String value) =>
      _preferences.setString(localeKey, value);

  Future<void> writeUsageDataSharing(bool value) =>
      _preferences.setBool(usageDataSharingKey, value);
}
