import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/mocks.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret1';
  const failure = Failure.auth(AuthFailureReason.invalidCredentials);

  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  blocTest<SignInCubit, SignInState>(
    'an empty form shows errors and sends nothing',
    build: () => SignInCubit(repository, FakeAnalyticsService()),
    act: (cubit) => cubit.submit(email: '', password: ''),
    expect: () => [
      const SignInState(
        emailError: AuthFieldError.emailEmpty,
        passwordError: AuthFieldError.passwordTooShort,
      ),
    ],
    verify: (_) => verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ),
  );

  blocTest<SignInCubit, SignInState>(
    'a malformed email and a short password are rejected',
    build: () => SignInCubit(repository, FakeAnalyticsService()),
    act: (cubit) => cubit.submit(email: 'user@example', password: '12345'),
    expect: () => [
      const SignInState(
        emailError: AuthFieldError.emailInvalid,
        passwordError: AuthFieldError.passwordTooShort,
      ),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'success goes through submitting',
    setUp: () {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
    },
    build: () => SignInCubit(repository, FakeAnalyticsService()),
    act: (cubit) => cubit.submit(email: email, password: password),
    expect: () => [
      const SignInState(isSubmitting: true),
      const SignInState(isSuccess: true),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'a failure is shown, and a new submit clears it',
    setUp: () {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
    },
    build: () => SignInCubit(repository, FakeAnalyticsService()),
    act: (cubit) async {
      await cubit.submit(email: email, password: password);
      await cubit.submit(email: email, password: password);
    },
    expect: () => [
      const SignInState(isSubmitting: true),
      const SignInState(failure: failure),
      const SignInState(isSubmitting: true),
      const SignInState(failure: failure),
    ],
  );

  group('analytics', () {
    late FakeAnalyticsService analytics;

    setUp(() => analytics = FakeAnalyticsService());

    test('a success logs the event with the method', () async {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
      final cubit = SignInCubit(repository, analytics);
      addTearDown(cubit.close);

      await cubit.submit(email: email, password: password);

      expect(analytics.events, [
        [
          AnalyticsEvents.login,
          {AnalyticsParams.method: AnalyticsValues.passwordMethod},
        ],
      ]);
    });

    test('a failure logs nothing', () async {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
      final cubit = SignInCubit(repository, analytics);
      addTearDown(cubit.close);

      await cubit.submit(email: email, password: password);

      expect(analytics.events, isEmpty);
    });
  });
}
