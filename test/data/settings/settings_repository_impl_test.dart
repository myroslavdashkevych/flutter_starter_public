import 'package:flutter_starter/data/settings/data_source/settings_prefs_data_source.dart';
import 'package:flutter_starter/data/settings/settings_repository_impl.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockDataSource extends Mock implements SettingsPrefsDataSource {}

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

  Future<AppSettings> loadValue(SettingsRepositoryImpl target) async {
    final result = await target.load();
    expect(result, isA<Ok<AppSettings>>());
    return (result as Ok<AppSettings>).value;
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
        await loadValue(repository),
        const AppSettings(
          themePreference: ThemePreference.dark,
          localePreference: LocalePreference.uk,
        ),
      );
    });

    test(
      'SET-1, SET-2: falls back to system when values are missing',
      () async {
        stubStored();

        expect(await loadValue(repository), const AppSettings());
      },
    );

    test('falls back to system for unknown values', () async {
      stubStored(theme: 'sepia', locale: 'de');

      expect(await loadValue(repository), const AppSettings());
    });

    test('reads the stored usage data choice over the default', () async {
      stubStored(usageDataSharing: false);

      expect((await loadValue(repository)).usageDataSharing, isFalse);
    });

    test(
      'SET-6: uses the default from the config when nothing is stored',
      () async {
        stubStored();
        final optIn = SettingsRepositoryImpl(dataSource, talker, false);

        expect((await loadValue(optIn)).usageDataSharing, isFalse);
      },
    );

    test('SET-6: a storage error returns the configured default', () async {
      when(() => dataSource.readTheme()).thenThrow(Exception('broken'));
      final optIn = SettingsRepositoryImpl(dataSource, talker, false);

      expect(
        await loadValue(optIn),
        const AppSettings(usageDataSharing: false),
      );
    });

    test('logs a storage error once', () async {
      when(() => dataSource.readTheme()).thenThrow(Exception('broken'));

      expect(await repository.load(), isA<Ok<AppSettings>>());
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
