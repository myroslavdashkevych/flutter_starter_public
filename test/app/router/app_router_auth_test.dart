import 'dart:async';

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
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/usecases/delete_account_use_case.dart';
import 'package:flutter_starter/domain/items/usecases/get_item_details_use_case.dart';
import 'package:flutter_starter/domain/items/usecases/get_items_page_use_case.dart';
import 'package:flutter_starter/domain/notifications/usecases/request_notification_permission_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_cubit.dart';
import 'package:flutter_starter/presentation/auth/pages/reset_password_page.dart';
import 'package:flutter_starter/presentation/auth/pages/sign_in_page.dart';
import 'package:flutter_starter/presentation/auth/pages/sign_up_page.dart';
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
  const email = 'user@example.com';
  const password = 'secret1';

  late MockAuthRepository authRepository;
  late FakeFavoritesRepository favorites;
  late StreamController<AppUser?> users;
  AppUser? currentUser;

  void emitUser(AppUser? user) {
    currentUser = user;
    users.add(user);
  }

  final signInPage = find.byType(SignInPage);
  final signUpPage = find.byType(SignUpPage);
  final resetPasswordPage = find.byType(ResetPasswordPage);
  final navigationBar = find.byType(NavigationBar);
  final signInButton = find.widgetWithText(FilledButton, 'Sign in');

  setUpAll(registerFallbackValues);

  setUp(() {
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
    when(() => itemsRepository.getById(2))
        .thenAnswer((_) async => const Err(Failure.notFound()));
    favorites = FakeFavoritesRepository();
    authRepository = MockAuthRepository();
    users = StreamController<AppUser?>.broadcast();
    currentUser = null;
    // Like Firebase: every new listener gets the current user first.
    when(authRepository.authStateChanges).thenAnswer(
      (_) => Stream.multi((listener) {
        listener.add(currentUser);
        final subscription = users.stream.listen(listener.add);
        listener.onCancel = () => unawaited(subscription.cancel());
      }),
    );
    when(() => authRepository.signIn(email: email, password: password))
        .thenAnswer((_) async {
          emitUser(testUser);
          return const Ok(testUser);
        });
    when(() => authRepository.signUp(email: email, password: password))
        .thenAnswer((_) async {
          emitUser(testUser);
          return const Ok(testUser);
        });
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
      )
      ..registerFactory(
        () => SignInCubit(authRepository, FakeAnalyticsService()),
      )
      ..registerFactory(
        () => SignUpCubit(authRepository, FakeAnalyticsService()),
      )
      ..registerFactory(
        () => ResetPasswordCubit(authRepository, FakeAnalyticsService()),
      )
      ..registerFactory(
        () => ProfileCubit(
          authRepository,
          DeleteAccountUseCase(
            authRepository,
            favorites,
            FakeAnalyticsService(),
          ),
        ),
      );
    registerFavoriteCubits(getIt, authRepository, favorites);
  });

  tearDown(() async {
    await users.close();
    await getIt.reset();
  });

  // Built inside each test, so that the bloc lives in the fake async zone.
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final authBloc = AuthBloc(authRepository);
    final settingsCubit = SettingsCubit(MockSettingsRepository());
    final router = createAppRouter(authBloc);
    addTearDown(() async {
      router.dispose();
      await authBloc.close();
      await settingsCubit.close();
    });
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(App(router: router, settingsCubit: settingsCubit));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NavigationDestination, label));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> openSignIn(WidgetTester tester) async {
    await tapTab(tester, 'Profile');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();
  }

  Future<void> submitSignIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  void expectSignedInProfile(GoRouter router) {
    expect(location(router), '/profile');
    expect(signInPage, findsNothing);
    expect(signUpPage, findsNothing);
    expect(navigationBar, findsOneWidget);
    expect(find.text(email), findsOneWidget);
  }

  group('guest', () {
    testWidgets(
      'NAV-1, NAV-4: starts on the items with the bottom navigation',
      (tester) async {
        final router = await pumpApp(tester);

        expect(location(router), '/items');
        expect(find.text('Item 1'), findsOneWidget);
        expect(navigationBar, findsOneWidget);
      },
    );

    testWidgets('NAV-4: reaches item details and settings', (tester) async {
      final router = await pumpApp(tester);

      await tapText(tester, 'Item 1');
      expect(location(router), '/items/1');
      expect(find.byType(ItemDetailsPage), findsOneWidget);

      await tapTab(tester, 'Settings');
      expect(location(router), '/settings');
      await tester.scrollUntilVisible(find.text('1.2.3 (4)'), 100);
      expect(find.text('1.2.3 (4)'), findsOneWidget);
    });

    testWidgets('opens the auth pages over the shell and goes back', (
      tester,
    ) async {
      await pumpApp(tester);

      await openSignIn(tester);
      expect(signInPage, findsOneWidget);
      expect(navigationBar, findsNothing);

      await tapText(tester, 'Create an account');
      expect(signUpPage, findsOneWidget);

      await tapText(tester, 'I already have an account');
      expect(signInPage, findsOneWidget);

      await tapText(tester, 'Forgot password?');
      expect(resetPasswordPage, findsOneWidget);

      await tapText(tester, 'Back to sign in');
      expect(signInPage, findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(signInPage, findsNothing);
      expect(navigationBar, findsOneWidget);
    });
  });

  group('after success', () {
    testWidgets('NAV-6: sign-in returns to the profile', (tester) async {
      final router = await pumpApp(tester);
      await openSignIn(tester);

      await submitSignIn(tester);

      expectSignedInProfile(router);
    });

    testWidgets('NAV-6: sign-up removes the whole auth stack', (tester) async {
      final router = await pumpApp(tester);
      await openSignIn(tester);
      await tapText(tester, 'Create an account');

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), password);
      await tester.enterText(fields.at(2), password);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expectSignedInProfile(router);
    });

    testWidgets('NAV-6: the other tabs keep their stacks', (tester) async {
      final router = await pumpApp(tester);
      await tapText(tester, 'Item 1');
      await openSignIn(tester);

      await submitSignIn(tester);
      await tapTab(tester, 'Items');

      expect(location(router), '/items/1');
    });
  });

  group('signed in', () {
    setUp(() => currentUser = testUser);

    for (final path in ['/sign-in', '/sign-up', '/reset-password']) {
      testWidgets('NAV-5: $path goes to the profile', (tester) async {
        final router = await pumpApp(tester);

        router.go(path);
        await tester.pumpAndSettle();

        expectSignedInProfile(router);
      });
    }

    testWidgets('PRF-4: signing out stays on the profile as a guest', (
      tester,
    ) async {
      final router = await pumpApp(tester);
      await tapTab(tester, 'Profile');

      emitUser(null);
      await tester.pumpAndSettle();

      expect(location(router), '/profile');
      expect(signInButton, findsOneWidget);
      expect(find.text(email), findsNothing);
    });
  });

  group('favorites', () {
    final toggleOff = find.byIcon(Icons.favorite_border);
    final toggleOn = find.byIcon(Icons.favorite);

    testWidgets('FAV-2: a guest sees no favorite controls', (tester) async {
      await pumpApp(tester);

      expect(find.text('Item 1'), findsOneWidget);
      expect(toggleOff, findsNothing);
      expect(toggleOn, findsNothing);

      await tapText(tester, 'Item 1');
      expect(toggleOff, findsNothing);

      await tapTab(tester, 'Profile');
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('FAV-6: a guest on the favorites route is asked to sign in', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      router.go('/profile/favorites');
      await tester.pumpAndSettle();

      expect(location(router), '/profile/favorites');
      expect(find.text('Sign in to save favorites'), findsOneWidget);

      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(signInPage, findsOneWidget);
    });

    group('signed in', () {
      setUp(() => currentUser = testUser);

      testWidgets('FAV-3: a change on one screen shows on the others', (
        tester,
      ) async {
        final router = await pumpApp(tester);

        await tester.tap(toggleOff);
        await tester.pumpAndSettle();
        expect(toggleOn, findsOneWidget);

        await tapTab(tester, 'Profile');
        await tapText(tester, 'Favorites');
        expect(location(router), '/profile/favorites');
        expect(find.text('Item 1'), findsOneWidget);

        await tester.tap(toggleOn);
        await tester.pumpAndSettle();
        expect(find.text('Item 1'), findsNothing);
        expect(find.textContaining('No favorites yet'), findsOneWidget);

        await tapTab(tester, 'Items');
        expect(toggleOff, findsOneWidget);
        expect(toggleOn, findsNothing);
      });

      testWidgets(
        'FAV-14: a favorite opens its details inside the profile tab',
        (tester) async {
          favorites.items.add(testItem(1));
          final router = await pumpApp(tester);
          await tapTab(tester, 'Profile');
          await tapText(tester, 'Favorites');

          await tester.tap(find.text('Item 1'));
          await tester.pumpAndSettle();

          expect(location(router), '/profile/favorites/1');
          expect(find.byType(ItemDetailsPage), findsOneWidget);
          expect(navigationBar, findsOneWidget);
          expect(toggleOn, findsOneWidget);

          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(location(router), '/profile/favorites');
        },
      );

      testWidgets(
        'FAV-10: a missing item can be removed and returns to the list',
        (tester) async {
          favorites.items.addAll([testItem(2), testItem(1)]);
          final router = await pumpApp(tester);
          await tapTab(tester, 'Profile');
          await tapText(tester, 'Favorites');

          await tester.tap(find.text('Item 2'));
          await tester.pumpAndSettle();

          expect(find.text('Nothing was found.'), findsOneWidget);
          expect(find.text('Retry'), findsNothing);

          await tester.tap(
            find.widgetWithText(FilledButton, 'Remove from favorites'),
          );
          await tester.pumpAndSettle();

          expect(location(router), '/profile/favorites');
          expect(find.text('Item 2'), findsNothing);
          expect(find.text('Item 1'), findsOneWidget);
        },
      );

      testWidgets(
        'FAV-10, ITM-15: a missing item in the items tab keeps the retry',
        (tester) async {
          final router = await pumpApp(tester);

          router.go('/items/2');
          await tester.pumpAndSettle();

          expect(find.text('Retry'), findsOneWidget);
          expect(find.text('Remove from favorites'), findsNothing);
        },
      );
    });
  });

  group('OBS-3: screen views', () {
    testWidgets('closing sign-in reports the tab under it', (tester) async {
      await pumpApp(tester);
      await openSignIn(tester);
      expect(analytics.screens.last, 'sign_in');
      analytics.screens.clear();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(analytics.screens, ['profile']);
    });

    testWidgets('a successful sign-in reports the profile', (tester) async {
      when(() => authRepository.signIn(email: email, password: password))
          .thenAnswer((_) async {
            emitUser(testUser);
            return const Ok(testUser);
          });
      await pumpApp(tester);
      await openSignIn(tester);
      analytics.screens.clear();

      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(analytics.screens, ['profile']);
    });

    testWidgets('a sign-in from the favorites page reports only the profile', (
      tester,
    ) async {
      when(() => authRepository.signIn(email: email, password: password))
          .thenAnswer((_) async {
            emitUser(testUser);
            return const Ok(testUser);
          });
      final router = await pumpApp(tester);
      await tapTab(tester, 'Profile');
      router.go('/profile/favorites');
      await tester.pumpAndSettle();
      await tester.tap(signInButton);
      await tester.pumpAndSettle();
      analytics.screens.clear();

      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(analytics.screens, ['profile']);
    });
  });
}
