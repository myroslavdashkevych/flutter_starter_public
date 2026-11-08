import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_cubit.dart';
import 'package:flutter_starter/presentation/auth/pages/sign_in_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/mocks.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret1';

  late MockAuthRepository repository;
  var signUpTaps = 0;
  var resetTaps = 0;
  var successes = 0;

  final submit = find.widgetWithText(FilledButton, 'Sign in');

  setUp(() {
    repository = MockAuthRepository();
    signUpTaps = 0;
    resetTaps = 0;
    successes = 0;
  });

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => SignInCubit(repository, FakeAnalyticsService()),
        child: SignInPage(
          onSignUp: () => signUpTaps++,
          onResetPassword: () => resetTaps++,
          onSuccess: () => successes++,
        ),
      ),
    ),
  );

  Future<void> fillForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, ' $email ');
    await tester.enterText(find.byType(TextField).last, password);
  }

  testWidgets('AUTH-1, AUTH-2: an empty form shows localized errors', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
  });

  testWidgets('AUTH-1: a malformed email shows its own error', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField).first, 'user@example');

    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets(
    'AUTH-4: submit is disabled while loading, with a trimmed email',
    (tester) async {
      final result = Completer<Result<AppUser>>();
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) => result.future);
      await pumpPage(tester);
      await fillForm(tester);

      await tester.tap(submit);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      result.complete(const Ok(testUser));
      await tester.pump();
      verify(() => repository.signIn(email: email, password: password))
          .called(1);
    },
  );

  testWidgets('AUTH-5: a failure shows a localized message', (tester) async {
    when(() => repository.signIn(email: email, password: password)).thenAnswer(
      (_) async =>
          const Err(Failure.auth(AuthFailureReason.invalidCredentials)),
    );
    await pumpPage(tester);
    await fillForm(tester);

    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(successes, 0);
  });

  testWidgets('success calls the callback once', (tester) async {
    when(() => repository.signIn(email: email, password: password))
        .thenAnswer((_) async => const Ok(testUser));
    await pumpPage(tester);
    await fillForm(tester);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(successes, 1);
  });

  testWidgets('links call their callbacks', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Forgot password?'));
    await tester.tap(find.text('Create an account'));

    expect(resetTaps, 1);
    expect(signUpTaps, 1);
  });
}
