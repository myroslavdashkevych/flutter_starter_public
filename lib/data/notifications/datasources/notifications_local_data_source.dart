import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class NotificationsLocalDataSource {
  NotificationsLocalDataSource(this._preferences);

  static const permissionRequestedKey = 'notifications.permission_requested';

  final SharedPreferencesAsync _preferences;

  Future<bool> readPermissionRequested() async =>
      await _preferences.getBool(permissionRequestedKey) ?? false;

  Future<void> writePermissionRequested() =>
      _preferences.setBool(permissionRequestedKey, true);
}
