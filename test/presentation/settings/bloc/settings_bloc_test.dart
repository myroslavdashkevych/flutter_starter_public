import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/use_case/settings/load_settings_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/save_settings_use_case.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_event.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/mock.dart';

void main() {
  late MockSettingsRepository repository;

  const dark = AppSettings(themePreference: ThemePreference.dark);
  const light = AppSettings(themePreference: ThemePreference.light);
  const uk = AppSettings(localePreference: LocalePreference.uk);

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  test('starts with the default settings, not loaded', () {
    expect(
      SettingsBloc(
        LoadSettingsUseCase(repository),
        SaveSettingsUseCase(repository),
      ).state,
      const SettingsState(),
    );
  });

  blocTest<SettingsBloc, SettingsState>(
    'load emits the stored settings',
    build: () {
      when(() => repository.load()).thenAnswer((_) async => const Ok(dark));
      return SettingsBloc(
        LoadSettingsUseCase(repository),
        SaveSettingsUseCase(repository),
      );
    },
    act: (bloc) => bloc.add(const SettingsLoadRequested()),
    expect: () => [const SettingsState(settings: dark, isLoaded: true)],
  );

  blocTest<SettingsBloc, SettingsState>(
    'SET-4: stored settings equal to the defaults still count as loaded',
    build: () {
      when(() => repository.load())
          .thenAnswer((_) async => const Ok(AppSettings()));
      return SettingsBloc(
        LoadSettingsUseCase(repository),
        SaveSettingsUseCase(repository),
      );
    },
    act: (bloc) => bloc.add(const SettingsLoadRequested()),
    expect: () => [const SettingsState(isLoaded: true)],
  );

  blocTest<SettingsBloc, SettingsState>(
    'SET-1: a theme change applies and saves the preference',
    build: () => SettingsBloc(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    ),
    act: (bloc) => bloc.add(const SettingsThemeChanged(ThemePreference.dark)),
    expect: () => [const SettingsState(settings: dark)],
    verify: (_) => verify(() => repository.save(dark)).called(1),
  );

  blocTest<SettingsBloc, SettingsState>(
    'SET-2: a locale change applies and saves the preference',
    build: () => SettingsBloc(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    ),
    act: (bloc) => bloc.add(const SettingsLocaleChanged(LocalePreference.uk)),
    expect: () => [const SettingsState(settings: uk)],
    verify: (_) => verify(() => repository.save(uk)).called(1),
  );

  blocTest<SettingsBloc, SettingsState>(
    'SET-6: a usage data sharing change applies and saves the choice',
    build: () => SettingsBloc(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    ),
    act: (bloc) => bloc.add(const SettingsUsageDataSharingChanged(false)),
    expect: () => [
      const SettingsState(settings: AppSettings(usageDataSharing: false)),
    ],
    verify: (_) => verify(
      () => repository.save(const AppSettings(usageDataSharing: false)),
    ).called(1),
  );

  blocTest<SettingsBloc, SettingsState>(
    'SET-5: keeps the new value and reports a failed save',
    build: () {
      when(() => repository.save(any()))
          .thenAnswer((_) async => const Err(Failure.cache()));
      return SettingsBloc(
        LoadSettingsUseCase(repository),
        SaveSettingsUseCase(repository),
      );
    },
    act: (bloc) => bloc.add(const SettingsThemeChanged(ThemePreference.dark)),
    expect: () => [
      const SettingsState(settings: dark),
      const SettingsState(settings: dark, saveFailure: Failure.cache()),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'SET-5: a new change clears the previous failure',
    build: () => SettingsBloc(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    ),
    seed: () => const SettingsState(saveFailure: Failure.cache()),
    act: (bloc) => bloc.add(const SettingsThemeChanged(ThemePreference.dark)),
    expect: () => [const SettingsState(settings: dark)],
  );

  test(
    'SET-12: quick changes are saved in order, the last one stored',
    () async {
      final firstSave = Completer<Result<void>>();
      final saved = <AppSettings>[];
      when(() => repository.save(any())).thenAnswer((invocation) {
        final settings = invocation.positionalArguments.single as AppSettings;
        saved.add(settings);
        return settings == dark
            ? firstSave.future
            : Future.value(const Ok(null));
      });
      final bloc = SettingsBloc(
        LoadSettingsUseCase(repository),
        SaveSettingsUseCase(repository),
      );
      addTearDown(bloc.close);

      bloc
        ..add(const SettingsThemeChanged(ThemePreference.dark))
        ..add(const SettingsThemeChanged(ThemePreference.light));
      await pumpEventQueue();
      expect(saved, [dark], reason: 'the second save waits for the first');

      firstSave.complete(const Ok(null));
      await pumpEventQueue();

      expect(saved, [dark, light]);
      expect(bloc.state.settings, light);
    },
  );
}
