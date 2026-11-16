import 'dart:async';

import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/router/app_router.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/delete_account_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/send_password_reset_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_in_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_out_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_up_use_case.dart';
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
import 'package:flutter_starter/presentation/auth/bloc/reset_password_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_bloc.dart';
import 'package:flutter_starter/presentation/auth/page/reset_password_page.dart';
import 'package:flutter_starter/presentation/auth/page/sign_in_page.dart';
import 'package:flutter_starter/presentation/auth/page/sign_up_page.dart';
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
  const email = 'user@example.com';
  const password = 'secret1';

  late MockAuthRepository authRepository;
  late FakeFavoriteRepository favorites;
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
    final characterRepository = MockCharacterRepository();
    when(() => characterRepository.getPage(page: 1))
        .thenAnswer((_) async => Ok(testPage(1, ids: [1], hasMore: false)));
    when(() => characterRepository.getById(1))
        .thenAnswer((_) async => Ok(testCharacter(1)));
    when(() => characterRepository.getById(2))
        .thenAnswer((_) async => const Err(Failure.notFound()));
    favorites = FakeFavoriteRepository();
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
      )
      ..registerFactory(
        () => SignInBloc(SignInUseCase(authRepository, FakeAnalyticsService())),
      )
      ..registerFactory(
        () => SignUpBloc(SignUpUseCase(authRepository, FakeAnalyticsService())),
      )
      ..registerFactory(
        () => ResetPasswordBloc(
          SendPasswordResetUseCase(authRepository, FakeAnalyticsService()),
        ),
      )
      ..registerFactory(
        () => ProfileBloc(
          WatchAuthStateUseCase(authRepository),
          SignOutUseCase(authRepository),
          DeleteAccountUseCase(
            authRepository,
            favorites,
            FakeAnalyticsService(),
          ),
        ),
      );
    registerFavoriteBlocs(getIt, authRepository, favorites);
  });

  tearDown(() async {
    await users.close();
    await getIt.reset();
  });

  // Built inside each test, so that the bloc lives in the fake async zone.
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final authBloc = AuthBloc(WatchAuthStateUseCase(authRepository));
    final settingsRepository = MockSettingsRepository();
    final settingsBloc = SettingsBloc(
      LoadSettingsUseCase(settingsRepository),
      SaveSettingsUseCase(settingsRepository),
    );
    final router = createAppRouter(authBloc);
    // In the fake zone the future of close() never completes, so it is not
    // awaited.
    addTearDown(() {
      router.dispose();
      unawaited(authBloc.close());
      unawaited(settingsBloc.close());
    });
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(App(router: router, settingsBloc: settingsBloc));
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
      'NAV-1, NAV-4: starts on the characters with the bottom navigation',
      (tester) async {
        final router = await pumpApp(tester);

        expect(location(router), '/character-list');
        expect(find.text('Character 1'), findsOneWidget);
        expect(navigationBar, findsOneWidget);
      },
    );

    testWidgets('NAV-4: reaches character details and settings', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      await tapText(tester, 'Character 1');
      expect(location(router), '/character-list/1');
      expect(find.byType(CharacterDetailPage), findsOneWidget);

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
      await tapText(tester, 'Character 1');
      await openSignIn(tester);

      await submitSignIn(tester);
      await tapTab(tester, 'Characters');

      expect(location(router), '/character-list/1');
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

      expect(find.text('Character 1'), findsOneWidget);
      expect(toggleOff, findsNothing);
      expect(toggleOn, findsNothing);

      await tapText(tester, 'Character 1');
      expect(toggleOff, findsNothing);

      await tapTab(tester, 'Profile');
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('FAV-6: a guest on the favorites route is asked to sign in', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      router.go('/profile/favorite-list');
      await tester.pumpAndSettle();

      expect(location(router), '/profile/favorite-list');
      expect(find.text('Sign in to save favorites'), findsOneWidget);

      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(signInPage, findsOneWidget);
    });

    testWidgets('FAV-6: a guest who signs in from there lands on the profile', (
      tester,
    ) async {
      when(() => authRepository.signIn(email: email, password: password))
          .thenAnswer((_) async {
            emitUser(testUser);
            return const Ok(testUser);
          });
      final router = await pumpApp(tester);
      router.go('/profile/favorite-list');
      await tester.pumpAndSettle();
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(location(router), '/profile');
    });

    group('signed in', () {
      setUp(() => currentUser = testUser);

      testWidgets('PRF-3: Favorites in the profile opens the favorites route', (
        tester,
      ) async {
        final router = await pumpApp(tester);

        await tapTab(tester, 'Profile');
        await tapText(tester, 'Favorites');

        expect(location(router), '/profile/favorite-list');
      });

      testWidgets('FAV-3: a change on one screen shows on the others', (
        tester,
      ) async {
        final router = await pumpApp(tester);

        await tester.tap(toggleOff);
        await tester.pumpAndSettle();
        expect(toggleOn, findsOneWidget);

        await tapTab(tester, 'Profile');
        await tapText(tester, 'Favorites');
        expect(location(router), '/profile/favorite-list');
        expect(find.text('Character 1'), findsOneWidget);

        await tester.tap(toggleOn);
        await tester.pumpAndSettle();
        expect(find.text('Character 1'), findsNothing);
        expect(find.textContaining('No favorites yet'), findsOneWidget);

        await tapTab(tester, 'Characters');
        expect(toggleOff, findsOneWidget);
        expect(toggleOn, findsNothing);
      });

      testWidgets(
        'FAV-14: a favorite opens its details inside the profile tab',
        (tester) async {
          favorites.characters.add(testCharacter(1));
          final router = await pumpApp(tester);
          await tapTab(tester, 'Profile');
          await tapText(tester, 'Favorites');

          await tester.tap(find.text('Character 1'));
          await tester.pumpAndSettle();

          expect(location(router), '/profile/favorite-list/1');
          expect(find.byType(CharacterDetailPage), findsOneWidget);
          expect(navigationBar, findsOneWidget);
          expect(toggleOn, findsOneWidget);

          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(location(router), '/profile/favorite-list');
        },
      );

      testWidgets(
        'FAV-10: a missing character can be removed and returns to the list',
        (tester) async {
          favorites.characters.addAll([testCharacter(2), testCharacter(1)]);
          final router = await pumpApp(tester);
          await tapTab(tester, 'Profile');
          await tapText(tester, 'Favorites');

          await tester.tap(find.text('Character 2'));
          await tester.pumpAndSettle();

          expect(find.text('Nothing was found.'), findsOneWidget);
          expect(find.text('Retry'), findsNothing);

          await tester.tap(
            find.widgetWithText(FilledButton, 'Remove from favorites'),
          );
          await tester.pumpAndSettle();

          expect(location(router), '/profile/favorite-list');
          expect(find.text('Character 2'), findsNothing);
          expect(find.text('Character 1'), findsOneWidget);
        },
      );

      testWidgets(
        'FAV-10, CHR-15: a missing character in the characters tab keeps the retry',
        (tester) async {
          final router = await pumpApp(tester);

          router.go('/character-list/2');
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
      router.go('/profile/favorite-list');
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
