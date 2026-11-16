import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_up_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret1';
  const submitted = SignUpSubmitted(
    email: email,
    password: password,
    confirmation: password,
  );
  const failure = Failure.auth(AuthFailureReason.emailAlreadyInUse);

  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  blocTest<SignUpBloc, SignUpState>(
    'AUTH-3: a different confirmation is rejected',
    build: () => SignUpBloc(SignUpUseCase(repository, FakeAnalyticsService())),
    act: (bloc) => bloc.add(
      const SignUpSubmitted(
        email: email,
        password: password,
        confirmation: 'secret2',
      ),
    ),
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

  blocTest<SignUpBloc, SignUpState>(
    'AUTH-1, AUTH-2: an empty email and a short password are rejected',
    build: () => SignUpBloc(SignUpUseCase(repository, FakeAnalyticsService())),
    act: (bloc) => bloc.add(
      const SignUpSubmitted(email: '', password: '123', confirmation: '123'),
    ),
    expect: () => [
      const SignUpState(
        emailError: AuthFieldError.emailEmpty,
        passwordError: AuthFieldError.passwordTooShort,
      ),
    ],
  );

  blocTest<SignUpBloc, SignUpState>(
    'AUTH-4: success goes through submitting',
    setUp: () {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
    },
    build: () => SignUpBloc(SignUpUseCase(repository, FakeAnalyticsService())),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const SignUpState(isSubmitting: true),
      const SignUpState(isSuccess: true),
    ],
  );

  final response = Completer<Result<AppUser>>();
  blocTest<SignUpBloc, SignUpState>(
    'AUTH-4: a repeated submit while one runs starts no second request',
    setUp: () {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) => response.future);
    },
    build: () => SignUpBloc(SignUpUseCase(repository, FakeAnalyticsService())),
    act: (bloc) async {
      bloc.add(submitted);
      await pumpEventQueue();
      bloc.add(submitted);
      await pumpEventQueue();
      response.complete(const Ok(testUser));
    },
    expect: () => [
      const SignUpState(isSubmitting: true),
      const SignUpState(isSuccess: true),
    ],
    verify: (_) =>
        verify(() => repository.signUp(email: email, password: password))
            .called(1),
  );

  blocTest<SignUpBloc, SignUpState>(
    'AUTH-5: a failure is shown',
    setUp: () {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
    },
    build: () => SignUpBloc(SignUpUseCase(repository, FakeAnalyticsService())),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const SignUpState(isSubmitting: true),
      const SignUpState(failure: failure),
    ],
  );

  test('OBS-7: the submit event shows neither password', () {
    const event = SignUpSubmitted(
      email: email,
      password: password,
      confirmation: 'other-secret',
    );

    expect(event.toString(), isNot(contains(password)));
    expect(event.toString(), isNot(contains('other-secret')));
  });

  group('AUTH-8: analytics', () {
    late FakeAnalyticsService analytics;

    setUp(() => analytics = FakeAnalyticsService());

    test('a success logs the event with the method', () async {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Ok(testUser));
      final bloc = SignUpBloc(SignUpUseCase(repository, analytics));
      addTearDown(bloc.close);

      bloc.add(submitted);
      await pumpEventQueue();

      expect(analytics.events, [const AnalyticsEvent.signedUp()]);
    });

    test('a failure logs nothing', () async {
      when(() => repository.signUp(email: email, password: password))
          .thenAnswer((_) async => const Err(failure));
      final bloc = SignUpBloc(SignUpUseCase(repository, analytics));
      addTearDown(bloc.close);

      bloc.add(submitted);
      await pumpEventQueue();

      expect(analytics.events, isEmpty);
    });
  });
}
