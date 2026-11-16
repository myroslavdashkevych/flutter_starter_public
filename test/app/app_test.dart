import 'dart:async';

import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/router/app_router.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/use_case/auth/delete_account_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_out_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_detail_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_page_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_character_opened_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_search_use_case.dart';
import 'package:flutter_starter/domain/use_case/observability/track_screen_view_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/load_settings_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/save_settings_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_bloc.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helper/auth_fixture.dart';
import '../helper/character_fixture.dart';
import '../helper/fake_analytics_service.dart';
import '../helper/fake_favorite_repository.dart';
import '../helper/mock.dart';

void main() {
  late MockSettingsRepository repository;
  late SettingsBloc settingsBloc;
  late AuthBloc authBloc;
  late GoRouter router;

  setUpAll(registerFallbackValues);

  setUp(() async {
    getIt
      ..registerSingleton(const AppInfo(version: '1.2.3 (4)'))
      ..registerSingleton(
        const AppConfig(
          flavor: Flavor.dev,
          rickAndMortyApiBaseUrl: 'https://characters.invalid',
          backendBaseUrl: 'https://backend.invalid',
          characterCacheTtlMinutes: 30,
          privacyPolicyUrl: 'https://privacy.invalid',
          usageDataSharingDefault: true,
        ),
      )
      ..registerSingleton(TrackScreenViewUseCase(FakeAnalyticsService()));
    final characterRepository = MockCharacterRepository();
    when(() => characterRepository.getPage(page: 1))
        .thenAnswer((_) async => Ok(testPage(1, ids: [1], hasMore: false)));
    when(() => characterRepository.getById(1))
        .thenAnswer((_) async => Ok(testCharacter(1)));
    getIt
      ..registerFactory(
        () => CharacterListBloc(
          GetCharacterPageUseCase(characterRepository),
          TrackSearchUseCase(FakeAnalyticsService()),
        ),
      )
      ..registerFactory(
        () => CharacterDetailBloc(
          GetCharacterDetailUseCase(characterRepository),
          TrackCharacterOpenedUseCase(FakeAnalyticsService()),
        ),
      );
    final AuthRepository authRepository = signedInAuthRepository();
    final favoriteRepository = FakeFavoriteRepository();
    getIt.registerFactory(
      () => ProfileBloc(
        WatchAuthStateUseCase(authRepository),
        SignOutUseCase(authRepository),
        DeleteAccountUseCase(
          authRepository,
          favoriteRepository,
          FakeAnalyticsService(),
        ),
      ),
    );
    registerFavoriteBlocs(getIt, authRepository, favoriteRepository);
    authBloc = AuthBloc(WatchAuthStateUseCase(authRepository));
    await authBloc.stream.first;
    repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
    router = createAppRouter(authBloc);
  });

  tearDown(() async {
    router.dispose();
    await authBloc.close();
    await getIt.reset();
  });

  // Made inside each test, so that the bloc handles its events in the fake
  // time of the widget test. There the future of close() never completes, so
  // it is not awaited.
  SettingsBloc newSettingsBloc() {
    final bloc = SettingsBloc(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    );
    addTearDown(() => unawaited(bloc.close()));
    return bloc;
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    List<Locale> deviceLocales = const [Locale('en')],
  }) async {
    tester.platformDispatcher.localesTestValue = deviceLocales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    settingsBloc = newSettingsBloc();
    await tester.pumpWidget(App(router: router, settingsBloc: settingsBloc));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  MaterialApp materialApp(WidgetTester tester) =>
      tester.widget(find.byType(MaterialApp));

  group('device language', () {
    testWidgets('SET-3: a supported language is used', (tester) async {
      await pumpApp(tester, deviceLocales: const [Locale('uk', 'UA')]);

      expect(find.text("Пошук за ім'ям"), findsOneWidget);
    });

    testWidgets('SET-3: an unsupported language falls back to English', (
      tester,
    ) async {
      await pumpApp(tester, deviceLocales: const [Locale('de')]);

      expect(find.text('Character 1'), findsOneWidget);
    });
  });

  testWidgets('SET-4: the first frame uses the saved theme and language', (
    tester,
  ) async {
    when(() => repository.load()).thenAnswer(
      (_) async => const Ok(
        AppSettings(
          themePreference: ThemePreference.dark,
          localePreference: LocalePreference.uk,
        ),
      ),
    );
    settingsBloc = newSettingsBloc()..add(const SettingsLoadRequested());
    await tester.pump();
    expect(settingsBloc.state.isLoaded, isTrue);

    await tester.pumpWidget(App(router: router, settingsBloc: settingsBloc));

    expect(materialApp(tester).themeMode, ThemeMode.dark);
    expect(materialApp(tester).locale, const Locale('uk'));
    await tester.pumpAndSettle();
  });

  group('settings page', () {
    testWidgets('SET-10: shows the app version', (tester) async {
      await pumpApp(tester);
      await openSettings(tester);

      await tester.scrollUntilVisible(find.text('1.2.3 (4)'), 100);

      expect(find.text('1.2.3 (4)'), findsOneWidget);
    });

    testWidgets(
      'SET-1: theme follows the system by default and switches live',
      (tester) async {
        await pumpApp(tester);
        await openSettings(tester);
        expect(materialApp(tester).themeMode, ThemeMode.system);

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(materialApp(tester).themeMode, ThemeMode.dark);
        verify(
          () => repository.save(
            const AppSettings(themePreference: ThemePreference.dark),
          ),
        ).called(1);
      },
    );

    testWidgets('SET-2: language switches live and back to the system', (
      tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      await tester.tap(find.text('Українська'));
      await tester.pumpAndSettle();

      expect(materialApp(tester).locale, const Locale('uk'));
      expect(find.text('Налаштування'), findsWidgets);

      await tester.tap(find.text('Системна').last);
      await tester.pumpAndSettle();

      expect(materialApp(tester).locale, isNull);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('SET-5: a failed save shows a message and keeps the value', (
      tester,
    ) async {
      when(() => repository.save(any()))
          .thenAnswer((_) async => const Err(Failure.cache()));
      await pumpApp(tester);
      await openSettings(tester);

      await tester.tap(find.text('Dark'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Could not save the data on this device.'),
        findsOneWidget,
      );
      expect(materialApp(tester).themeMode, ThemeMode.dark);
    });
  });
}
