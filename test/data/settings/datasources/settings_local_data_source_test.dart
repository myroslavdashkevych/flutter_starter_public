import 'package:flutter_starter/data/settings/datasources/settings_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPreferences extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPreferences preferences;
  late SettingsLocalDataSource dataSource;

  setUp(() {
    preferences = _MockPreferences();
    dataSource = SettingsLocalDataSource(preferences);
  });

  test('reads the theme and locale from their keys', () async {
    when(() => preferences.getString('settings.theme'))
        .thenAnswer((_) async => 'dark');
    when(() => preferences.getString('settings.locale'))
        .thenAnswer((_) async => 'uk');

    expect(await dataSource.readTheme(), 'dark');
    expect(await dataSource.readLocale(), 'uk');
  });

  test('writes the theme and locale to their keys', () async {
    when(() => preferences.setString(any(), any())).thenAnswer((_) async {});

    await dataSource.writeTheme('dark');
    await dataSource.writeLocale('uk');

    verify(() => preferences.setString('settings.theme', 'dark')).called(1);
    verify(() => preferences.setString('settings.locale', 'uk')).called(1);
  });

  test('reads and writes the usage data choice under its key', () async {
    when(() => preferences.getBool('settings.usage_data_sharing'))
        .thenAnswer((_) async => false);
    when(() => preferences.setBool(any(), any())).thenAnswer((_) async {});

    expect(await dataSource.readUsageDataSharing(), isFalse);
    await dataSource.writeUsageDataSharing(true);

    verify(() => preferences.setBool('settings.usage_data_sharing', true))
        .called(1);
  });
}
