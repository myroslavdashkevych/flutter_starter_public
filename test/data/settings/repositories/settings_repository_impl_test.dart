import 'package:flutter_starter/data/settings/datasources/settings_local_data_source.dart';
import 'package:flutter_starter/data/settings/repositories/settings_repository_impl.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockDataSource extends Mock implements SettingsLocalDataSource {}

void main() {
  late _MockDataSource dataSource;
  late Talker talker;
  late SettingsRepositoryImpl repository;

  void stubStored({String? theme, String? locale, bool? usageDataSharing}) {
    when(() => dataSource.readTheme()).thenAnswer((_) async => theme);
    when(() => dataSource.readLocale()).thenAnswer((_) async => locale);
    when(() => dataSource.readUsageDataSharing())
        .thenAnswer((_) async => usageDataSharing);
  }

  setUp(() {
    dataSource = _MockDataSource();
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    repository = SettingsRepositoryImpl(dataSource, talker, true);
  });

  group('load', () {
    test('maps stored enum names', () async {
      stubStored(theme: 'dark', locale: 'uk');

      expect(
        await repository.load(),
        const AppSettings(
          themePreference: ThemePreference.dark,
          localePreference: LocalePreference.uk,
        ),
      );
    });

    test('falls back to system when values are missing', () async {
      stubStored();

      expect(await repository.load(), const AppSettings());
    });

    test('falls back to system for unknown values', () async {
      stubStored(theme: 'sepia', locale: 'de');

      expect(await repository.load(), const AppSettings());
    });

    test('reads the stored usage data choice over the default', () async {
      stubStored(usageDataSharing: false);

      expect((await repository.load()).usageDataSharing, isFalse);
    });

    test('uses the default from the config when nothing is stored', () async {
      stubStored();
      final optIn = SettingsRepositoryImpl(dataSource, talker, false);

      expect((await optIn.load()).usageDataSharing, isFalse);
    });

    test('a storage error also uses the default from the config', () async {
      when(() => dataSource.readTheme()).thenThrow(Exception('broken'));
      final optIn = SettingsRepositoryImpl(dataSource, talker, false);

      expect((await optIn.load()).usageDataSharing, isFalse);
    });

    test('logs a storage error and returns the defaults', () async {
      when(() => dataSource.readTheme()).thenThrow(Exception('broken'));

      expect(await repository.load(), const AppSettings());
      expect(talker.history, hasLength(1));
    });
  });

  group('save', () {
    const settings = AppSettings(
      themePreference: ThemePreference.light,
      localePreference: LocalePreference.en,
      usageDataSharing: false,
    );

    test('writes enum names and returns Ok', () async {
      when(() => dataSource.writeTheme(any())).thenAnswer((_) async {});
      when(() => dataSource.writeLocale(any())).thenAnswer((_) async {});
      when(() => dataSource.writeUsageDataSharing(any()))
          .thenAnswer((_) async {});

      final result = await repository.save(settings);

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.writeTheme('light')).called(1);
      verify(() => dataSource.writeLocale('en')).called(1);
      verify(() => dataSource.writeUsageDataSharing(false)).called(1);
    });

    test('logs a storage error and returns CacheFailure', () async {
      when(() => dataSource.writeTheme(any())).thenThrow(Exception('broken'));

      final result = await repository.save(settings);

      expect((result as Err<void>).failure, const Failure.cache());
      expect(talker.history, hasLength(1));
    });
  });
}
