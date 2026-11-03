import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/mocks.dart';

void main() {
  const email = 'user@example.com';
  const failure = Failure.auth(AuthFailureReason.network);

  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  blocTest<ResetPasswordCubit, ResetPasswordState>(
    'a malformed email is rejected',
    build: () => ResetPasswordCubit(repository, FakeAnalyticsService()),
    act: (cubit) => cubit.submit(email: 'nope'),
    expect: () => [
      const ResetPasswordState(emailError: AuthFieldError.emailInvalid),
    ],
    verify: (_) => verifyNever(
      () => repository.sendPasswordReset(email: any(named: 'email')),
    ),
  );

  blocTest<ResetPasswordCubit, ResetPasswordState>(
    'success ends in the sent state',
    setUp: () {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Ok(null));
    },
    build: () => ResetPasswordCubit(repository, FakeAnalyticsService()),
    act: (cubit) => cubit.submit(email: email),
    expect: () => [
      const ResetPasswordState(isSubmitting: true),
      const ResetPasswordState(isSent: true),
    ],
  );

  blocTest<ResetPasswordCubit, ResetPasswordState>(
    'a failure is shown',
    setUp: () {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Err(failure));
    },
    build: () => ResetPasswordCubit(repository, FakeAnalyticsService()),
    act: (cubit) => cubit.submit(email: email),
    expect: () => [
      const ResetPasswordState(isSubmitting: true),
      const ResetPasswordState(failure: failure),
    ],
  );

  group('analytics', () {
    late FakeAnalyticsService analytics;

    setUp(() => analytics = FakeAnalyticsService());

    test('a success logs the event', () async {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Ok(null));
      final cubit = ResetPasswordCubit(repository, analytics);
      addTearDown(cubit.close);

      await cubit.submit(email: email);

      expect(analytics.events, [
        [AnalyticsEvents.passwordResetRequested, null],
      ]);
    });

    test('a failure logs nothing', () async {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Err(failure));
      final cubit = ResetPasswordCubit(repository, analytics);
      addTearDown(cubit.close);

      await cubit.submit(email: email);

      expect(analytics.events, isEmpty);
    });
  });
}
