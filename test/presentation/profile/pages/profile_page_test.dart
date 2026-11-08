import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/usecases/delete_account_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_cubit.dart';
import 'package:flutter_starter/presentation/profile/pages/profile_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/fake_favorites_repository.dart';
import '../../../helpers/mocks.dart';

void main() {
  const password = 'secret1';

  late MockAuthRepository repository;

  late FakeFavoritesRepository favoritesRepository;

  var signInTaps = 0;
  var favoritesTaps = 0;

  final deleteButton = find.widgetWithText(TextButton, 'Delete');
  final signInButton = find.widgetWithText(FilledButton, 'Sign in');

  setUp(() {
    repository = signedInAuthRepository();
    favoritesRepository = FakeFavoritesRepository();
    signInTaps = 0;
    favoritesTaps = 0;
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => ProfileCubit(
            repository,
            DeleteAccountUseCase(
              repository,
              favoritesRepository,
              FakeAnalyticsService(),
            ),
          ),
          child: ProfilePage(
            onSignIn: () => signInTaps++,
            onFavorites: () => favoritesTaps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
  }

  testWidgets('PRF-3: shows the signed-in email', (tester) async {
    await pumpPage(tester);

    expect(find.text(testUser.email!), findsOneWidget);
    expect(signInButton, findsNothing);
  });

  testWidgets('PRF-3: a signed-in user opens the favorites', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Favorites'));

    expect(favoritesTaps, 1);
  });

  testWidgets(
    'PRF-1: an unknown auth state shows neither form of the profile',
    (tester) async {
      when(repository.authStateChanges)
          .thenAnswer((_) => const Stream<AppUser?>.empty());

      await pumpPage(tester);

      expect(signInButton, findsNothing);
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('Sign in to manage your account.'), findsNothing);
    },
  );

  group('guest', () {
    setUp(() {
      when(repository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
    });

    testWidgets('FAV-2, PRF-2: sees the explanation and no account actions', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Sign in to manage your account.'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('Delete account'), findsNothing);
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('PRF-2: the button calls its callback', (tester) async {
      await pumpPage(tester);

      await tester.tap(signInButton);

      expect(signInTaps, 1);
    });
  });

  testWidgets('PRF-4: switches to the guest state when the user signs out', (
    tester,
  ) async {
    final users = StreamController<AppUser?>();
    addTearDown(users.close);
    when(repository.authStateChanges).thenAnswer((_) => users.stream);
    await pumpPage(tester);
    users.add(testUser);
    await tester.pumpAndSettle();
    expect(find.text(testUser.email!), findsOneWidget);

    users.add(null);
    await tester.pumpAndSettle();

    expect(find.text(testUser.email!), findsNothing);
    expect(signInButton, findsOneWidget);
  });

  group('sign out', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
    }

    testWidgets('PRF-4: cancel does not sign out', (tester) async {
      await pumpPage(tester);
      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(repository.signOut);
    });

    testWidgets('PRF-4: confirm signs out', (tester) async {
      when(repository.signOut).thenAnswer((_) async => const Ok(null));
      await pumpPage(tester);
      await openDialog(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      verify(repository.signOut).called(1);
    });

    testWidgets('a failure shows a message', (tester) async {
      when(repository.signOut)
          .thenAnswer((_) async => const Err(Failure.network()));
      await pumpPage(tester);
      await openDialog(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
    });
  });

  group('delete account', () {
    testWidgets('PRF-5: warns and needs a password', (tester) async {
      await pumpPage(tester);
      await openDeleteDialog(tester);

      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(tester.widget<TextButton>(deleteButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField), password);
      await tester.pump();

      expect(tester.widget<TextButton>(deleteButton).onPressed, isNotNull);
    });

    testWidgets(
      'PRF-7: a wrong password keeps the dialog open with a message',
      (tester) async {
        when(() => repository.reauthenticate(password: password)).thenAnswer(
          (_) async =>
              const Err(Failure.auth(AuthFailureReason.invalidCredentials)),
        );
        await pumpPage(tester);
        await openDeleteDialog(tester);
        await tester.enterText(find.byType(TextField), password);
        await tester.pump();

        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        expect(find.text('Wrong email or password.'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
        verifyNever(repository.deleteAccount);
      },
    );

    testWidgets('PRF-5: success deletes the account and closes the dialog', (
      tester,
    ) async {
      when(() => repository.reauthenticate(password: password))
          .thenAnswer((_) async => const Ok(null));
      when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));
      await pumpPage(tester);
      await openDeleteDialog(tester);
      await tester.enterText(find.byType(TextField), password);
      await tester.pump();

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      verify(repository.deleteAccount).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
