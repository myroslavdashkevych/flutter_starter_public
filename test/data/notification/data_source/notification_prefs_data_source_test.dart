import 'package:flutter_starter/data/notification/data_source/notification_prefs_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPreferences extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPreferences preferences;
  late NotificationPrefsDataSource dataSource;

  setUp(() {
    preferences = _MockPreferences();
    dataSource = NotificationPrefsDataSource(preferences);
  });

  test('a missing flag reads as false', () async {
    when(() => preferences.getBool('notification.permission_requested'))
        .thenAnswer((_) async => null);

    expect(await dataSource.readPermissionRequested(), isFalse);
  });

  test('writes the flag to its key', () async {
    when(() => preferences.setBool(any(), any())).thenAnswer((_) async {});

    await dataSource.writePermissionRequested();

    verify(() => preferences.setBool('notification.permission_requested', true))
        .called(1);
  });
}
