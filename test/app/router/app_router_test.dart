import 'package:flutter/material.dart';
import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/router/app_router.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/auth/usecases/delete_account_use_case.dart';
import 'package:flutter_starter/domain/items/usecases/get_item_details_use_case.dart';
import 'package:flutter_starter/domain/items/usecases/get_items_page_use_case.dart';
import 'package:flutter_starter/domain/notifications/usecases/request_notification_permission_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_cubit.dart';
import 'package:flutter_starter/presentation/item_details/pages/item_details_page.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_cubit.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fake_analytics_service.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/items_fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late FakeAnalyticsService analytics;
  late SettingsCubit cubit;
  late AuthBloc authBloc;
  late GoRouter router;

  const openItem = 'Item 1';
  final itemDetails = find.byType(ItemDetailsPage);

  setUpAll(registerFallbackValues);

  setUp(() async {
    getIt
      ..registerSingleton(const AppInfo(version: '1.2.3 (4)'))
      ..registerSingleton(
        const AppConfig(
          flavor: Flavor.dev,
          itemsApiBaseUrl: 'https://items.invalid',
          backendBaseUrl: 'https://backend.invalid',
          itemsCacheTtlMinutes: 30,
          privacyPolicyUrl: 'https://privacy.invalid',
          usageDataSharingDefault: true,
        ),
      )
      ..registerSingleton<AnalyticsService>(analytics = FakeAnalyticsService())
      ..registerSingleton(Talker());
    final itemsRepository = MockItemsRepository();
    when(() => itemsRepository.getPage(page: 1))
        .thenAnswer((_) async => Ok(testPage(1, ids: [1], hasMore: false)));
    when(() => itemsRepository.getById(1))
        .thenAnswer((_) async => Ok(testItem(1)));
    getIt
      ..registerFactory(
        () => ItemsListBloc(
          GetItemsPageUseCase(itemsRepository),
          FakeAnalyticsService(),
        ),
      )
      ..registerFactory(
        () => ItemDetailsCubit(
          GetItemDetailsUseCase(itemsRepository),
          FakeAnalyticsService(),
        ),
      )
      ..registerFactory(
        () =>
            RequestNotificationPermissionUseCase(FakeNotificationsRepository()),
      );
    final AuthRepository authRepository = signedInAuthRepository();
    final favoritesRepository = FakeFavoritesRepository();
    getIt.registerFactory(
      () => ProfileCubit(
        authRepository,
        DeleteAccountUseCase(
          authRepository,
          favoritesRepository,
          FakeAnalyticsService(),
        ),
      ),
    );
    registerFavoriteCubits(getIt, authRepository, favoritesRepository);
    authBloc = AuthBloc(authRepository);
    await authBloc.stream.first;
    final repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
    cubit = SettingsCubit(repository);
    router = createAppRouter(authBloc);
  });

  tearDown(() async {
    router.dispose();
    await authBloc.close();
    await cubit.close();
    await getIt.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(App(router: router, settingsCubit: cubit));
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NavigationDestination, label));
    await tester.pumpAndSettle();
  }

  Future<void> openFirstItem(WidgetTester tester) async {
    await tester.tap(find.text(openItem));
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('NAV-1: starts on the items tab', (tester) async {
    await pumpApp(tester);

    expect(location(), '/items');
    expect(find.text(openItem), findsOneWidget);
  });

  // FCM copies `data.route` to the launch intent, and FlutterActivity reads the
  // `route` extra as the platform default route.
  testWidgets('NAV-1: ignores the platform default route', (tester) async {
    tester.platformDispatcher.defaultRouteNameTestValue = '/unknown';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    router.dispose();
    router = createAppRouter(authBloc);

    await pumpApp(tester);

    expect(location(), '/items');
    expect(find.text(openItem), findsOneWidget);
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

    await tapTab(tester, 'Items');
    expect(location(), '/items');
  });

  testWidgets('ITM-1: an item opens by its id inside the items tab', (
    tester,
  ) async {
    await pumpApp(tester);

    await openFirstItem(tester);

    expect(location(), '/items/1');
    expect(itemDetails, findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  group('notification permission', () {
    late FakeNotificationsRepository notAsked;

    setUp(() {
      notAsked = FakeNotificationsRepository(asked: false);
      getIt
        ..unregister<RequestNotificationPermissionUseCase>()
        ..registerFactory(() => RequestNotificationPermissionUseCase(notAsked));
    });

    testWidgets('NTF-1, NTF-2, NTF-3: the first opened item asks; "Not now" '
        'keeps the system request', (tester) async {
      await pumpApp(tester);
      analytics.screens.clear();

      await openFirstItem(tester);
      expect(find.text('Turn on notifications?'), findsOneWidget);
      expect(analytics.screens, ['item_details']);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Turn on notifications?'), findsNothing);
      expect(itemDetails, findsOneWidget);
      expect(notAsked.permissionRequests, 0);
      expect(notAsked.asked, isTrue);
      expect(analytics.screens, ['item_details']);
    });

    testWidgets('NTF-2: "Allow" leads to the system request', (tester) async {
      await pumpApp(tester);
      await openFirstItem(tester);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(notAsked.permissionRequests, 1);
    });

    testWidgets('NTF-2: the next opened item does not ask again', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstItem(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await openFirstItem(tester);

      expect(find.text('Turn on notifications?'), findsNothing);
    });
  });

  testWidgets('NAV-3: a tab keeps its own stack', (tester) async {
    await pumpApp(tester);
    await openFirstItem(tester);

    await tapTab(tester, 'Settings');
    expect(itemDetails, findsNothing);

    await tapTab(tester, 'Items');
    expect(location(), '/items/1');
    expect(itemDetails, findsOneWidget);
  });

  testWidgets('the app bar back button returns to the list', (tester) async {
    await pumpApp(tester);
    await openFirstItem(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(location(), '/items');
    expect(find.text(openItem), findsOneWidget);
  });

  testWidgets('the system back button returns to the list', (tester) async {
    await pumpApp(tester);
    await openFirstItem(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(location(), '/items');
    expect(find.text(openItem), findsOneWidget);
  });

  testWidgets('tapping the active tab returns to its root', (tester) async {
    await pumpApp(tester);
    await openFirstItem(tester);

    await tapTab(tester, 'Items');

    expect(location(), '/items');
    expect(find.text(openItem), findsOneWidget);
  });

  testWidgets('changing the theme keeps the current location', (tester) async {
    await pumpApp(tester);
    await openFirstItem(tester);
    await tapTab(tester, 'Settings');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(location(), '/settings');
    await tapTab(tester, 'Items');
    expect(location(), '/items/1');
  });

  group('OBS-3: screen views', () {
    testWidgets('the first screen is reported once by its name', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(analytics.screens, ['items']);
    });

    testWidgets('a pushed item reports the route name, not the id', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstItem(tester);

      expect(analytics.screens, ['items', 'item_details']);
    });

    testWidgets('going back reports the previous screen', (tester) async {
      await pumpApp(tester);
      await openFirstItem(tester);
      analytics.screens.clear();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(analytics.screens, ['items']);
    });

    testWidgets('a tab shown for the first time reports once', (tester) async {
      await pumpApp(tester);
      analytics.screens.clear();

      await tapTab(tester, 'Settings');

      expect(analytics.screens, ['settings']);
    });

    testWidgets('returning to a tab reports its top route', (tester) async {
      await pumpApp(tester);
      await openFirstItem(tester);
      await tapTab(tester, 'Settings');
      analytics.screens.clear();

      await tapTab(tester, 'Items');

      expect(analytics.screens, ['item_details']);
    });

    testWidgets('tapping the active tab on a nested route reports its root', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstItem(tester);
      analytics.screens.clear();

      await tapTab(tester, 'Items');

      expect(analytics.screens, ['items']);
    });

    testWidgets('tapping the active tab on its root reports nothing', (
      tester,
    ) async {
      await pumpApp(tester);
      analytics.screens.clear();

      await tapTab(tester, 'Items');

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
        getIt
          ..unregister<AppConfig>()
          ..registerSingleton(
            const AppConfig(
              flavor: Flavor.prod,
              itemsApiBaseUrl: 'https://items.invalid',
              backendBaseUrl: 'https://backend.invalid',
              itemsCacheTtlMinutes: 30,
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
