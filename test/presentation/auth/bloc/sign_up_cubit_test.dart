import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/mocks.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret1';
  const failure = Failure.auth(AuthFailureReason.emailAlreadyInUse);

  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  blocTest<SignUpCubit, SignUpState>(
    'AUTH-3: a different confirmation is rejected',
    build: () => SignUpCubit(repository, FakeAnalyticsService()),
    act: (cubit) =>
        cubit.submit(email: email, password: password, confirmation: 'secret2'),
    expect: () => [
      const SignUpState(confirmationError: AuthFieldError.passwordsDoNotMatch),
    ],
    verify: (_) => verifyNever(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ),
  );

  blocTest<SignUpCubit, SignUpState>(
    'AUTH-1, AUTH-2: an empty email and a short password are rejected',
    build: () => SignUpCubit(repository, FakeAnalyticsService()),
    act: (cubit) =>
        cubit.submit(email: '', password: '123', confirmation: '123'),
    expect: () => [
      const SignUpState(
        emailError: AuthFieldError.emailEmpty,
        passwordError: AuthFieldError.passwordTooShort,
      ),
    ],
  );

  blocTest<SignUpCubit, SignUpState>(
    'AUTH-4: success goes through submitting',
    setUp: () {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
    },
    build: () => SignUpCubit(repository, FakeAnalyticsService()),
    act: (cubit) =>
        cubit.submit(email: email, password: password, confirmation: password),
    expect: () => [
      const SignUpState(isSubmitting: true),
      const SignUpState(isSuccess: true),
    ],
  );

  blocTest<SignUpCubit, SignUpState>(
    'AUTH-5: a failure is shown',
    setUp: () {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
    },
    build: () => SignUpCubit(repository, FakeAnalyticsService()),
    act: (cubit) =>
        cubit.submit(email: email, password: password, confirmation: password),
    expect: () => [
      const SignUpState(isSubmitting: true),
      const SignUpState(failure: failure),
    ],
  );

  group('AUTH-8: analytics', () {
    late FakeAnalyticsService analytics;

    setUp(() => analytics = FakeAnalyticsService());

    test('a success logs the event with the method', () async {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
      final cubit = SignUpCubit(repository, analytics);
      addTearDown(cubit.close);

      await cubit.submit(
        email: email,
        password: password,
        confirmation: password,
      );

      expect(analytics.events, [
        [
          AnalyticsEvents.signUp,
          {AnalyticsParams.method: AnalyticsValues.passwordMethod},
        ],
      ]);
    });

    test('a failure logs nothing', () async {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
      final cubit = SignUpCubit(repository, analytics);
      addTearDown(cubit.close);

      await cubit.submit(
        email: email,
        password: password,
        confirmation: password,
      );

      expect(analytics.events, isEmpty);
    });
  });
}
