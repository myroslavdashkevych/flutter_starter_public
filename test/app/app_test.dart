import 'package:flutter/material.dart';
import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/router/app_router.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/auth/usecases/delete_account_use_case.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/domain/items/usecases/get_item_details_use_case.dart';
import 'package:flutter_starter/domain/items/usecases/get_items_page_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_cubit.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_cubit.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/auth_fixtures.dart';
import '../helpers/fake_analytics_service.dart';
import '../helpers/fake_favorites_repository.dart';
import '../helpers/items_fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockSettingsRepository repository;
  late SettingsCubit cubit;
  late AuthBloc authBloc;
  late GoRouter router;

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
      ..registerSingleton<AnalyticsService>(FakeAnalyticsService());
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
    repository = MockSettingsRepository();
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

  Future<void> pumpApp(
    WidgetTester tester, {
    List<Locale> deviceLocales = const [Locale('en')],
  }) async {
    tester.platformDispatcher.localesTestValue = deviceLocales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(App(router: router, settingsCubit: cubit));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  MaterialApp materialApp(WidgetTester tester) =>
      tester.widget(find.byType(MaterialApp));

  group('device language', () {
    testWidgets('a supported language is used', (tester) async {
      await pumpApp(tester, deviceLocales: const [Locale('uk', 'UA')]);

      expect(find.text("Пошук за ім'ям"), findsOneWidget);
    });

    testWidgets('an unsupported language falls back to English', (
      tester,
    ) async {
      await pumpApp(tester, deviceLocales: const [Locale('de')]);

      expect(find.text('Item 1'), findsOneWidget);
    });
  });

  group('settings page', () {
    testWidgets('shows the app version', (tester) async {
      await pumpApp(tester);
      await openSettings(tester);

      await tester.scrollUntilVisible(find.text('1.2.3 (4)'), 100);

      expect(find.text('1.2.3 (4)'), findsOneWidget);
    });

    testWidgets('theme follows the system by default and switches live', (
      tester,
    ) async {
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
    });

    testWidgets('language switches live and back to the system', (
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

    testWidgets('a failed save shows a message and keeps the value', (
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
