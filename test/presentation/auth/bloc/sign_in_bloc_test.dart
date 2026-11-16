import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_in_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret1';
  const submitted = SignInSubmitted(email: email, password: password);
  const failure = Failure.auth(AuthFailureReason.invalidCredentials);

  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  blocTest<SignInBloc, SignInState>(
    'AUTH-1, AUTH-2: an empty form shows errors and sends nothing',
    build: () => SignInBloc(SignInUseCase(repository, FakeAnalyticsService())),
    act: (bloc) => bloc.add(const SignInSubmitted(email: '', password: '')),
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

  blocTest<SignInBloc, SignInState>(
    'AUTH-1, AUTH-2: a malformed email and a short password are rejected',
    build: () => SignInBloc(SignInUseCase(repository, FakeAnalyticsService())),
    act: (bloc) => bloc.add(
      const SignInSubmitted(email: 'user@example', password: '12345'),
    ),
    expect: () => [
      const SignInState(
        emailError: AuthFieldError.emailInvalid,
        passwordError: AuthFieldError.passwordTooShort,
      ),
    ],
  );

  blocTest<SignInBloc, SignInState>(
    'AUTH-4: success goes through submitting',
    setUp: () {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
    },
    build: () => SignInBloc(SignInUseCase(repository, FakeAnalyticsService())),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const SignInState(isSubmitting: true),
      const SignInState(isSuccess: true),
    ],
  );

  final response = Completer<Result<AppUser>>();
  blocTest<SignInBloc, SignInState>(
    'AUTH-4: a repeated submit while one runs starts no second request',
    setUp: () {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) => response.future);
    },
    build: () => SignInBloc(SignInUseCase(repository, FakeAnalyticsService())),
    act: (bloc) async {
      bloc.add(submitted);
      await pumpEventQueue();
      bloc.add(submitted);
      await pumpEventQueue();
      response.complete(const Ok(testUser));
    },
    expect: () => [
      const SignInState(isSubmitting: true),
      const SignInState(isSuccess: true),
    ],
    verify: (_) =>
        verify(() => repository.signIn(email: email, password: password))
            .called(1),
  );

  blocTest<SignInBloc, SignInState>(
    'AUTH-5: a failure is shown, and a new submit clears it',
    setUp: () {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
    },
    build: () => SignInBloc(SignInUseCase(repository, FakeAnalyticsService())),
    act: (bloc) async {
      bloc.add(submitted);
      await pumpEventQueue();
      bloc.add(submitted);
    },
    expect: () => [
      const SignInState(isSubmitting: true),
      const SignInState(failure: failure),
      const SignInState(isSubmitting: true),
      const SignInState(failure: failure),
    ],
  );

  test('OBS-7: the submit event does not show the password', () {
    expect(submitted.toString(), isNot(contains(password)));
    expect(submitted.toString(), contains(email));
  });

  group('AUTH-8: analytics', () {
    late FakeAnalyticsService analytics;

    setUp(() => analytics = FakeAnalyticsService());

    test('a success logs the event with the method', () async {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
      final bloc = SignInBloc(SignInUseCase(repository, analytics));
      addTearDown(bloc.close);

      bloc.add(submitted);
      await pumpEventQueue();

      expect(analytics.events, [const AnalyticsEvent.signedIn()]);
    });

    test('a failure logs nothing', () async {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
      final bloc = SignInBloc(SignInUseCase(repository, analytics));
      addTearDown(bloc.close);

      bloc.add(submitted);
      await pumpEventQueue();

      expect(analytics.events, isEmpty);
    });
  });
}
