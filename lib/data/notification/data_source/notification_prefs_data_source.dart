import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class NotificationPrefsDataSource {
  NotificationPrefsDataSource(this._preferences);

  final SharedPreferencesAsync _preferences;

  static const permissionRequestedKey = 'notification.permission_requested';

  Future<bool> readPermissionRequested() async =>
      await _preferences.getBool(permissionRequestedKey) ?? false;

  Future<void> writePermissionRequested() =>
      _preferences.setBool(permissionRequestedKey, true);
}
