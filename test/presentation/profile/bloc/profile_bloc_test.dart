import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/delete_account_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_out_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_event.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/fake_favorite_repository.dart';
import '../../../helper/mock.dart';

void main() {
  const password = 'secret1';

  late MockAuthRepository repository;

  ProfileBloc build() => ProfileBloc(
    WatchAuthStateUseCase(repository),
    SignOutUseCase(repository),
    DeleteAccountUseCase(
      repository,
      FakeFavoriteRepository(),
      FakeAnalyticsService(),
    ),
  );

  setUp(() {
    repository = MockAuthRepository();
    when(repository.authStateChanges)
        .thenAnswer((_) => const Stream<AppUser?>.empty());
  });

  blocTest<ProfileBloc, ProfileState>(
    'PRF-1: the auth state is unknown until the first event',
    build: build,
    verify: (bloc) => expect(bloc.state.isAuthKnown, isFalse),
  );

  blocTest<ProfileBloc, ProfileState>(
    'PRF-3: shows the current user and follows changes',
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

  blocTest<ProfileBloc, ProfileState>(
    'PRF-2: a guest is known without a user',
    setUp: () {
      when(repository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
    },
    build: build,
    expect: () => [const ProfileState(isAuthKnown: true)],
  );

  test('stops following the user when closed', () async {
    final users = StreamController<AppUser?>();
    addTearDown(users.close);
    when(repository.authStateChanges).thenAnswer((_) => users.stream);
    final bloc = build();
    await pumpEventQueue();
    expect(users.hasListener, isTrue);

    await bloc.close();

    expect(users.hasListener, isFalse);
  });

  blocTest<ProfileBloc, ProfileState>(
    'PRF-4: a successful sign-out leaves no failure',
    setUp: () {
      when(repository.signOut).thenAnswer((_) async => const Ok(null));
    },
    build: build,
    act: (bloc) => bloc.add(const ProfileSignOutRequested()),
    expect: () => [const ProfileState()],
    verify: (_) => verify(repository.signOut).called(1),
  );

  blocTest<ProfileBloc, ProfileState>(
    'PRF-4: a failed sign-out reports the failure',
    setUp: () {
      when(repository.signOut)
          .thenAnswer((_) async => const Err(Failure.network()));
    },
    build: build,
    act: (bloc) => bloc.add(const ProfileSignOutRequested()),
    expect: () => [
      const ProfileState(),
      const ProfileState(signOutFailure: Failure.network()),
    ],
  );

  blocTest<ProfileBloc, ProfileState>(
    'PRF-5: a successful deletion goes through deleting',
    setUp: () {
      when(() => repository.reauthenticate(password: password))
          .thenAnswer((_) async => const Ok(null));
      when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));
    },
    build: build,
    act: (bloc) async {
      // After the bloc has subscribed, so that its state stays out of this.
      await pumpEventQueue();
      when(repository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(testUser));
      bloc.add(const ProfileDeleteRequested(password: password));
    },
    expect: () => [const ProfileState(isDeleting: true), const ProfileState()],
  );

  blocTest<ProfileBloc, ProfileState>(
    'PRF-7: a wrong password keeps the account, and a retry clears the failure',
    setUp: () {
      when(() => repository.reauthenticate(password: password)).thenAnswer(
        (_) async =>
            const Err(Failure.auth(AuthFailureReason.invalidCredentials)),
      );
    },
    build: build,
    act: (bloc) async {
      bloc.add(const ProfileDeleteRequested(password: password));
      await pumpEventQueue();
      bloc.add(const ProfileDeleteRequested(password: password));
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

  group('PRF-9: account actions do not overlap', () {
    late Completer<Result<void>> response;

    setUp(() => response = Completer<Result<void>>());

    blocTest<ProfileBloc, ProfileState>(
      'PRF-9: a repeated deletion while one runs starts no second request',
      setUp: () {
        when(() => repository.reauthenticate(password: password))
            .thenAnswer((_) => response.future);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const ProfileDeleteRequested(password: password));
        await pumpEventQueue();
        bloc.add(const ProfileDeleteRequested(password: password));
        await pumpEventQueue();
        response.complete(
          const Err(Failure.auth(AuthFailureReason.invalidCredentials)),
        );
      },
      expect: () => [
        const ProfileState(isDeleting: true),
        const ProfileState(
          deleteFailure: Failure.auth(AuthFailureReason.invalidCredentials),
        ),
      ],
      verify: (_) =>
          verify(() => repository.reauthenticate(password: password)).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'PRF-9: a repeated sign-out while one runs starts no second request',
      setUp: () {
        when(repository.signOut).thenAnswer((_) => response.future);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const ProfileSignOutRequested());
        await pumpEventQueue();
        bloc.add(const ProfileSignOutRequested());
        await pumpEventQueue();
        response.complete(const Ok(null));
      },
      verify: (_) => verify(repository.signOut).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'PRF-9: a sign-out while the deletion runs starts nothing',
      setUp: () {
        when(() => repository.reauthenticate(password: password))
            .thenAnswer((_) => response.future);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const ProfileDeleteRequested(password: password));
        await pumpEventQueue();
        bloc.add(const ProfileSignOutRequested());
        await pumpEventQueue();
        response.complete(
          const Err(Failure.auth(AuthFailureReason.invalidCredentials)),
        );
      },
      verify: (_) => verifyNever(repository.signOut),
    );
  });

  test('OBS-7: the delete event does not show the password', () {
    expect(
      const ProfileDeleteRequested(password: password).toString(),
      isNot(contains(password)),
    );
  });
}
