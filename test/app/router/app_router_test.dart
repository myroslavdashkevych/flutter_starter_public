import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/router/app_router.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/use_case/auth/delete_account_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_out_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_detail_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_page_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_character_opened_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_search_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/request_notification_permission_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/should_ask_notification_permission_use_case.dart';
import 'package:flutter_starter/domain/use_case/observability/track_screen_view_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/load_settings_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/save_settings_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_bloc.dart';
import 'package:flutter_starter/presentation/character_detail/page/character_detail_page.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../helper/auth_fixture.dart';
import '../../helper/character_fixture.dart';
import '../../helper/fake_analytics_service.dart';
import '../../helper/fake_favorite_repository.dart';
import '../../helper/fake_notification_repository.dart';
import '../../helper/mock.dart';

void main() {
  late FakeAnalyticsService analytics;
  late SettingsBloc settingsBloc;
  late MockCharacterRepository characterRepository;
  late AuthBloc authBloc;
  late GoRouter router;

  const openCharacter = 'Character 1';
  final characterDetail = find.byType(CharacterDetailPage);

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
      ..registerSingleton(
        TrackScreenViewUseCase(analytics = FakeAnalyticsService()),
      )
      ..registerSingleton(Talker());
    characterRepository = MockCharacterRepository();
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
      )
      ..registerFactory(
        () => ShouldAskNotificationPermissionUseCase(
          FakeNotificationRepository(),
        ),
      )
      ..registerFactory(
        () =>
            RequestNotificationPermissionUseCase(FakeNotificationRepository()),
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
    final repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
    settingsBloc = SettingsBloc(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    );
    router = createAppRouter(authBloc);
  });

  tearDown(() async {
    router.dispose();
    await authBloc.close();
    await settingsBloc.close();
    await getIt.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(App(router: router, settingsBloc: settingsBloc));
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NavigationDestination, label));
    await tester.pumpAndSettle();
  }

  Future<void> openFirstCharacter(WidgetTester tester) async {
    await tester.tap(find.text(openCharacter));
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('NAV-1: starts on the characters tab', (tester) async {
    await pumpApp(tester);

    expect(location(), '/character-list');
    expect(find.text(openCharacter), findsOneWidget);
  });

  // FCM copies `data.route` to the launch intent, and FlutterActivity reads the
  // `route` extra as the platform default route.
  testWidgets('NAV-1: ignores the platform default route', (tester) async {
    tester.platformDispatcher.defaultRouteNameTestValue = '/unknown';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    router.dispose();
    router = createAppRouter(authBloc);

    await pumpApp(tester);

    expect(location(), '/character-list');
    expect(find.text(openCharacter), findsOneWidget);
  });

  testWidgets('every tab opens its page', (tester) async {
    await pumpApp(tester);

    await tapTab(tester, 'Profile');
    expect(location(), '/profile');
    expect(find.text(testUser.email!), findsOneWidget);

    await tapTab(tester, 'Settings');
    expect(location(), '/settings');
    await tester.scrollUntilVisible(find.text('1.2.3 (4)'), 100);
    expect(find.text('1.2.3 (4)'), findsOneWidget);

    await tapTab(tester, 'Characters');
    expect(location(), '/character-list');
  });

  testWidgets('CHR-1: a character opens by its id inside the characters tab', (
    tester,
  ) async {
    await pumpApp(tester);

    await openFirstCharacter(tester);

    expect(location(), '/character-list/1');
    expect(characterDetail, findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  group('notification permission', () {
    late FakeNotificationRepository notAsked;

    setUp(() {
      notAsked = FakeNotificationRepository(asked: false);
      getIt
        ..unregister<ShouldAskNotificationPermissionUseCase>()
        ..unregister<RequestNotificationPermissionUseCase>()
        ..registerFactory(
          () => ShouldAskNotificationPermissionUseCase(notAsked),
        )
        ..registerFactory(() => RequestNotificationPermissionUseCase(notAsked));
    });

    testWidgets(
      'NTF-1, NTF-2, NTF-3: the first opened character asks; "Not now" '
      'keeps the system request',
      (tester) async {
        await pumpApp(tester);
        analytics.screens.clear();

        await openFirstCharacter(tester);
        expect(find.text('Turn on notifications?'), findsOneWidget);
        expect(analytics.screens, ['character_detail']);

        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();

        expect(find.text('Turn on notifications?'), findsNothing);
        expect(characterDetail, findsOneWidget);
        expect(notAsked.permissionRequests, 0);
        expect(notAsked.asked, isTrue);
        expect(analytics.screens, ['character_detail']);
      },
    );

    testWidgets('NTF-1: a failed load and its retry do not ask', (
      tester,
    ) async {
      when(() => characterRepository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
      await pumpApp(tester);
      await openFirstCharacter(tester);
      expect(find.text('Turn on notifications?'), findsNothing);

      when(() => characterRepository.getById(1))
          .thenAnswer((_) async => Ok(testCharacter(1)));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Character 1'), findsWidgets);
      expect(find.text('Turn on notifications?'), findsNothing);
      expect(notAsked.asked, isFalse);
    });

    testWidgets('NTF-2: "Allow" leads to the system request', (tester) async {
      await pumpApp(tester);
      await openFirstCharacter(tester);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(notAsked.permissionRequests, 1);
    });

    testWidgets('NTF-2: the next opened character does not ask again', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstCharacter(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await openFirstCharacter(tester);

      expect(find.text('Turn on notifications?'), findsNothing);
    });
  });

  testWidgets('NAV-3: a tab keeps its own stack', (tester) async {
    await pumpApp(tester);
    await openFirstCharacter(tester);

    await tapTab(tester, 'Settings');
    expect(characterDetail, findsNothing);

    await tapTab(tester, 'Characters');
    expect(location(), '/character-list/1');
    expect(characterDetail, findsOneWidget);
  });

  testWidgets('the app bar back button returns to the list', (tester) async {
    await pumpApp(tester);
    await openFirstCharacter(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(location(), '/character-list');
    expect(find.text(openCharacter), findsOneWidget);
  });

  testWidgets('the system back button returns to the list', (tester) async {
    await pumpApp(tester);
    await openFirstCharacter(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(location(), '/character-list');
    expect(find.text(openCharacter), findsOneWidget);
  });

  testWidgets('tapping the active tab returns to its root', (tester) async {
    await pumpApp(tester);
    await openFirstCharacter(tester);

    await tapTab(tester, 'Characters');

    expect(location(), '/character-list');
    expect(find.text(openCharacter), findsOneWidget);
  });

  testWidgets('changing the theme keeps the current location', (tester) async {
    await pumpApp(tester);
    await openFirstCharacter(tester);
    await tapTab(tester, 'Settings');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(location(), '/settings');
    await tapTab(tester, 'Characters');
    expect(location(), '/character-list/1');
  });

  group('OBS-3: screen views', () {
    testWidgets('the first screen is reported once by its name', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(analytics.screens, ['character_list']);
    });

    testWidgets('a pushed character reports the route name, not the id', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstCharacter(tester);

      expect(analytics.screens, ['character_list', 'character_detail']);
    });

    testWidgets('going back reports the previous screen', (tester) async {
      await pumpApp(tester);
      await openFirstCharacter(tester);
      analytics.screens.clear();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(analytics.screens, ['character_list']);
    });

    testWidgets('a tab shown for the first time reports once', (tester) async {
      await pumpApp(tester);
      analytics.screens.clear();

      await tapTab(tester, 'Settings');

      expect(analytics.screens, ['settings']);
    });

    testWidgets('returning to a tab reports its top route', (tester) async {
      await pumpApp(tester);
      await openFirstCharacter(tester);
      await tapTab(tester, 'Settings');
      analytics.screens.clear();

      await tapTab(tester, 'Characters');

      expect(analytics.screens, ['character_detail']);
    });

    testWidgets('tapping the active tab on a nested route reports its root', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstCharacter(tester);
      analytics.screens.clear();

      await tapTab(tester, 'Characters');

      expect(analytics.screens, ['character_list']);
    });

    testWidgets('tapping the active tab on its root reports nothing', (
      tester,
    ) async {
      await pumpApp(tester);
      analytics.screens.clear();

      await tapTab(tester, 'Characters');

      expect(analytics.screens, isEmpty);
    });
  });

  group('logs', () {
    testWidgets(
      'NAV-7, OBS-6, SET-11: dev shows the entry and opens the logs',
      (tester) async {
        await pumpApp(tester);
        await tapTab(tester, 'Settings');

        await tester.scrollUntilVisible(find.text('Logs'), 100);
        await tester.tap(find.text('Logs'));
        await tester.pumpAndSettle();

        expect(location(), '/settings/logs');
        expect(analytics.screens.last, 'logs');
      },
    );

    testWidgets(
      'NAV-7, SET-11: prod hides the entries and redirects the route',
      (tester) async {
        await getIt.unregister<AppConfig>();
        getIt.registerSingleton(
          const AppConfig(
            flavor: Flavor.prod,
            rickAndMortyApiBaseUrl: 'https://characters.invalid',
            backendBaseUrl: 'https://backend.invalid',
            characterCacheTtlMinutes: 30,
            privacyPolicyUrl: 'https://privacy.invalid',
            usageDataSharingDefault: true,
          ),
        );
        await pumpApp(tester);
        await tapTab(tester, 'Settings');

        await tester.scrollUntilVisible(find.text('1.2.3 (4)'), 100);
        await tester.pumpAndSettle();
        expect(find.text('Logs'), findsNothing);
        expect(find.text('Test crash'), findsNothing);

        router.go('/settings/logs');
        await tester.pumpAndSettle();

        expect(location(), '/settings');
      },
    );
  });
}
