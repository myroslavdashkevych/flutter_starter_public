import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/mocks.dart';

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
    final bloc = AuthBloc(repository);

    expect(bloc.state, const AuthState.unknown());
    await bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'follows sign-in and sign-out',
    build: () => AuthBloc(repository),
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
    build: () => AuthBloc(repository),
    act: (_) => users.add(null),
    expect: () => [const AuthState.unauthenticated()],
  );
}
