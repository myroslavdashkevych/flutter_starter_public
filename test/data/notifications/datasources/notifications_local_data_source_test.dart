import 'package:flutter_starter/data/notifications/datasources/notifications_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPreferences extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPreferences preferences;
  late NotificationsLocalDataSource dataSource;

  setUp(() {
    preferences = _MockPreferences();
    dataSource = NotificationsLocalDataSource(preferences);
  });

  test('a missing flag reads as false', () async {
    when(() => preferences.getBool('notifications.permission_requested'))
        .thenAnswer((_) async => null);

    expect(await dataSource.readPermissionRequested(), isFalse);
  });

  test('writes the flag to its key', () async {
    when(() => preferences.setBool(any(), any())).thenAnswer((_) async {});

    await dataSource.writePermissionRequested();

    verify(
      () => preferences.setBool('notifications.permission_requested', true),
    ).called(1);
  });
}
