import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockSettingsRepository repository;

  const dark = AppSettings(themePreference: ThemePreference.dark);
  const uk = AppSettings(localePreference: LocalePreference.uk);

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  test('starts with the default settings', () {
    expect(SettingsCubit(repository).state, const SettingsState());
  });

  blocTest<SettingsCubit, SettingsState>(
    'load emits the stored settings',
    build: () {
      when(() => repository.load()).thenAnswer((_) async => dark);
      return SettingsCubit(repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [const SettingsState(settings: dark)],
  );

  blocTest<SettingsCubit, SettingsState>(
    'SET-1: setTheme applies and saves the preference',
    build: () => SettingsCubit(repository),
    act: (cubit) => cubit.setTheme(ThemePreference.dark),
    expect: () => [const SettingsState(settings: dark)],
    verify: (_) => verify(() => repository.save(dark)).called(1),
  );

  blocTest<SettingsCubit, SettingsState>(
    'SET-2: setLocale applies and saves the preference',
    build: () => SettingsCubit(repository),
    act: (cubit) => cubit.setLocale(LocalePreference.uk),
    expect: () => [const SettingsState(settings: uk)],
    verify: (_) => verify(() => repository.save(uk)).called(1),
  );

  blocTest<SettingsCubit, SettingsState>(
    'SET-6: setUsageDataSharing applies and saves the choice',
    build: () => SettingsCubit(repository),
    act: (cubit) => cubit.setUsageDataSharing(false),
    expect: () => [
      const SettingsState(settings: AppSettings(usageDataSharing: false)),
    ],
    verify: (_) => verify(
      () => repository.save(const AppSettings(usageDataSharing: false)),
    ).called(1),
  );

  blocTest<SettingsCubit, SettingsState>(
    'SET-5: keeps the new value and reports a failed save',
    build: () {
      when(() => repository.save(any()))
          .thenAnswer((_) async => const Err(Failure.cache()));
      return SettingsCubit(repository);
    },
    act: (cubit) => cubit.setTheme(ThemePreference.dark),
    expect: () => [
      const SettingsState(settings: dark),
      const SettingsState(settings: dark, saveFailure: Failure.cache()),
    ],
  );

  blocTest<SettingsCubit, SettingsState>(
    'SET-5: a new change clears the previous failure',
    build: () => SettingsCubit(repository),
    seed: () => const SettingsState(saveFailure: Failure.cache()),
    act: (cubit) => cubit.setTheme(ThemePreference.dark),
    expect: () => [const SettingsState(settings: dark)],
  );
}
