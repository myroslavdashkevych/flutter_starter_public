import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/send_password_reset_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  const email = 'user@example.com';
  const submitted = ResetPasswordSubmitted(email: email);
  const failure = Failure.network();

  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  blocTest<ResetPasswordBloc, ResetPasswordState>(
    'AUTH-1: a malformed email is rejected',
    build: () => ResetPasswordBloc(
      SendPasswordResetUseCase(repository, FakeAnalyticsService()),
    ),
    act: (bloc) => bloc.add(const ResetPasswordSubmitted(email: 'nope')),
    expect: () => [
      const ResetPasswordState(emailError: AuthFieldError.emailInvalid),
    ],
    verify: (_) => verifyNever(
      () => repository.sendPasswordReset(email: any(named: 'email')),
    ),
  );

  blocTest<ResetPasswordBloc, ResetPasswordState>(
    'success ends in the sent state',
    setUp: () {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Ok(null));
    },
    build: () => ResetPasswordBloc(
      SendPasswordResetUseCase(repository, FakeAnalyticsService()),
    ),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ResetPasswordState(isSubmitting: true),
      const ResetPasswordState(isSent: true),
    ],
  );

  final response = Completer<Result<void>>();
  blocTest<ResetPasswordBloc, ResetPasswordState>(
    'AUTH-4: a repeated submit while one runs starts no second request',
    setUp: () {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) => response.future);
    },
    build: () => ResetPasswordBloc(
      SendPasswordResetUseCase(repository, FakeAnalyticsService()),
    ),
    act: (bloc) async {
      bloc.add(submitted);
      await pumpEventQueue();
      bloc.add(submitted);
      await pumpEventQueue();
      response.complete(const Ok(null));
    },
    expect: () => [
      const ResetPasswordState(isSubmitting: true),
      const ResetPasswordState(isSent: true),
    ],
    verify: (_) =>
        verify(() => repository.sendPasswordReset(email: email)).called(1),
  );

  blocTest<ResetPasswordBloc, ResetPasswordState>(
    'AUTH-5: a failure is shown',
    setUp: () {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Err(failure));
    },
    build: () => ResetPasswordBloc(
      SendPasswordResetUseCase(repository, FakeAnalyticsService()),
    ),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ResetPasswordState(isSubmitting: true),
      const ResetPasswordState(failure: failure),
    ],
  );

  group('AUTH-8: analytics', () {
    late FakeAnalyticsService analytics;

    setUp(() => analytics = FakeAnalyticsService());

    test('a success logs the event', () async {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Ok(null));
      final bloc = ResetPasswordBloc(
        SendPasswordResetUseCase(repository, analytics),
      );
      addTearDown(bloc.close);

      bloc.add(submitted);
      await pumpEventQueue();

      expect(analytics.events, [const AnalyticsEvent.passwordResetRequested()]);
    });

    test('a failure logs nothing', () async {
      when(() => repository.sendPasswordReset(email: email))
          .thenAnswer((_) async => const Err(failure));
      final bloc = ResetPasswordBloc(
        SendPasswordResetUseCase(repository, analytics),
      );
      addTearDown(bloc.close);

      bloc.add(submitted);
      await pumpEventQueue();

      expect(analytics.events, isEmpty);
    });
  });
}
