import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/data/auth/data_source/auth_firebase_data_source.dart';
import 'package:flutter_starter/data/auth/data_source/auth_firebase_exception.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/mock.dart';

void main() {
  late MockFirebaseAuth auth;
  late AuthFirebaseDataSource dataSource;

  setUp(() {
    auth = MockFirebaseAuth();
    dataSource = AuthFirebaseDataSource(auth);
  });

  group('errors', () {
    test('a Firebase error leaves as AuthFirebaseException with its failure '
        'and code', () async {
      when(auth.signOut)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await expectLater(
        dataSource.signOut(),
        throwsA(
          isA<AuthFirebaseException>()
              .having((e) => e.failure, 'failure', const Failure.network())
              .having((e) => e.code, 'code', 'network-request-failed'),
        ),
      );
    });

    test('other errors pass through', () async {
      when(auth.signOut).thenThrow(StateError('boom'));

      await expectLater(dataSource.signOut(), throwsA(isA<StateError>()));
    });

    test(
      'AUTH-7: an unknown address in a reset request is not an error',
      () async {
        when(() => auth.sendPasswordResetEmail(email: 'user@example.com'))
            .thenThrow(FirebaseAuthException(code: 'user-not-found'));

        await expectLater(
          dataSource.sendPasswordReset(email: 'user@example.com'),
          completes,
        );
      },
    );
  });

  group('TokenProvider', () {
    test('returns null without a signed-in user', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(await dataSource.getToken(), isNull);
    });

    test('returns the token of the current user', () async {
      final user = MockFirebaseUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(false)).thenAnswer((_) async => 'token');

      expect(await dataSource.getToken(), 'token');
    });

    test('passes forceRefresh to Firebase', () async {
      final user = MockFirebaseUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'fresh');

      expect(await dataSource.getToken(forceRefresh: true), 'fresh');
    });

    test('onUnauthorized signs out', () async {
      when(auth.signOut).thenAnswer((_) async {});

      await dataSource.onUnauthorized();

      verify(auth.signOut).called(1);
    });
  });
}
