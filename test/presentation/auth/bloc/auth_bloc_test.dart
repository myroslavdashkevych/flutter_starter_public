import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/mock.dart';

void main() {
  late MockAuthRepository repository;
  late StreamController<AppUser?> users;

  setUp(() {
    repository = MockAuthRepository();
    users = StreamController<AppUser?>();
    when(repository.authStateChanges).thenAnswer((_) => users.stream);
  });

  tearDown(() => users.close());

  test('starts unknown', () async {
    final bloc = AuthBloc(WatchAuthStateUseCase(repository));

    expect(bloc.state, const AuthState.unknown());
    await bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'follows sign-in and sign-out',
    build: () => AuthBloc(WatchAuthStateUseCase(repository)),
    act: (_) {
      users
        ..add(testUser)
        ..add(null);
    },
    expect: () => [
      const AuthState.authenticated(testUser),
      const AuthState.unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'no user at startup means signed out',
    build: () => AuthBloc(WatchAuthStateUseCase(repository)),
    act: (_) => users.add(null),
    expect: () => [const AuthState.unauthenticated()],
  );

  test('stops following the auth state when closed', () async {
    final bloc = AuthBloc(WatchAuthStateUseCase(repository));
    await pumpEventQueue();
    expect(users.hasListener, isTrue);

    await bloc.close();

    expect(users.hasListener, isFalse);
  });
}
