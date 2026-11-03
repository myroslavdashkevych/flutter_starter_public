import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/usecases/delete_account_use_case.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_cubit.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/fake_favorites_repository.dart';
import '../../../helpers/mocks.dart';

void main() {
  const password = 'secret1';

  late MockAuthRepository repository;

  ProfileCubit build() => ProfileCubit(
    repository,
    DeleteAccountUseCase(
      repository,
      FakeFavoritesRepository(),
      FakeAnalyticsService(),
    ),
  );

  setUp(() {
    repository = MockAuthRepository();
    when(repository.authStateChanges)
        .thenAnswer((_) => const Stream<AppUser?>.empty());
  });

  blocTest<ProfileCubit, ProfileState>(
    'the auth state is unknown until the first event',
    build: build,
    verify: (cubit) => expect(cubit.state.isAuthKnown, isFalse),
  );

  blocTest<ProfileCubit, ProfileState>(
    'shows the current user and follows changes',
    setUp: () {
      when(repository.authStateChanges)
          .thenAnswer((_) => Stream.fromIterable([testUser, null]));
    },
    build: build,
    expect: () => [
      const ProfileState(user: testUser, isAuthKnown: true),
      const ProfileState(isAuthKnown: true),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'a guest is known without a user',
    setUp: () {
      when(repository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
    },
    build: build,
    expect: () => [const ProfileState(isAuthKnown: true)],
  );

  blocTest<ProfileCubit, ProfileState>(
    'a successful sign-out leaves no failure',
    setUp: () {
      when(repository.signOut).thenAnswer((_) async => const Ok(null));
    },
    build: build,
    act: (cubit) => cubit.signOut(),
    expect: () => [const ProfileState()],
    verify: (_) => verify(repository.signOut).called(1),
  );

  blocTest<ProfileCubit, ProfileState>(
    'a failed sign-out reports the failure',
    setUp: () {
      when(repository.signOut)
          .thenAnswer((_) async => const Err(Failure.network()));
    },
    build: build,
    act: (cubit) => cubit.signOut(),
    expect: () => [
      const ProfileState(),
      const ProfileState(signOutFailure: Failure.network()),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'a successful deletion goes through deleting',
    setUp: () {
      when(() => repository.reauthenticate(password: password))
          .thenAnswer((_) async => const Ok(null));
      when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));
    },
    build: build,
    act: (cubit) {
      // After the cubit has subscribed, so that its state stays out of this.
      when(repository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(testUser));
      return cubit.deleteAccount(password: password);
    },
    expect: () => [const ProfileState(isDeleting: true), const ProfileState()],
  );

  blocTest<ProfileCubit, ProfileState>(
    'a wrong password keeps the account, and a retry clears the failure',
    setUp: () {
      when(() => repository.reauthenticate(password: password)).thenAnswer(
        (_) async =>
            const Err(Failure.auth(AuthFailureReason.invalidCredentials)),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.deleteAccount(password: password);
      await cubit.deleteAccount(password: password);
    },
    expect: () => [
      const ProfileState(isDeleting: true),
      const ProfileState(
        deleteFailure: Failure.auth(AuthFailureReason.invalidCredentials),
      ),
      const ProfileState(isDeleting: true),
      const ProfileState(
        deleteFailure: Failure.auth(AuthFailureReason.invalidCredentials),
      ),
    ],
    verify: (_) => verifyNever(repository.deleteAccount),
  );
}
