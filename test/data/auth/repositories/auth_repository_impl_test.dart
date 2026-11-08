import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/data/auth/repositories/auth_repository_impl.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../../helpers/mocks.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret1';
  const appUser = AppUser(id: 'user-1', email: email);

  late MockFirebaseAuth auth;
  late MockFirebaseUser user;
  late Talker talker;
  late AuthRepositoryImpl repository;

  Matcher failsWith(AuthFailureReason reason) => isA<Err<dynamic>>().having(
    (error) => error.failure,
    'failure',
    Failure.auth(reason),
  );

  setUpAll(registerFallbackValues);

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockFirebaseUser();
    when(() => user.uid).thenReturn(appUser.id);
    when(() => user.email).thenReturn(email);
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    repository = AuthRepositoryImpl(auth, talker);
  });

  test('authStateChanges maps users and sign-outs', () {
    when(auth.authStateChanges)
        .thenAnswer((_) => Stream.fromIterable([user, null]));

    expect(repository.authStateChanges(), emitsInOrder([appUser, null]));
  });

  group('signIn', () {
    test('returns the signed-in user', () async {
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(
        () => auth.signInWithEmailAndPassword(email: email, password: password),
      ).thenAnswer((_) async => credential);

      final result = await repository.signIn(email: email, password: password);

      expect(
        result,
        isA<Ok<AppUser>>().having((ok) => ok.value, 'value', appUser),
      );
    });

    test('AUTH-5: maps the Firebase error code', () async {
      when(
        () => auth.signInWithEmailAndPassword(email: email, password: password),
      ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      expect(
        await repository.signIn(email: email, password: password),
        failsWith(AuthFailureReason.invalidCredentials),
      );
      expect(talker.history, isEmpty);
    });

    test('logs an unknown Firebase error code', () async {
      when(
        () => auth.signInWithEmailAndPassword(email: email, password: password),
      ).thenThrow(FirebaseAuthException(code: 'something-new'));

      expect(
        await repository.signIn(email: email, password: password),
        failsWith(AuthFailureReason.unknown),
      );
      expect(talker.history, hasLength(1));
    });

    test('never throws on other exceptions', () async {
      when(
        () => auth.signInWithEmailAndPassword(email: email, password: password),
      ).thenThrow(StateError('boom'));

      expect(
        await repository.signIn(email: email, password: password),
        failsWith(AuthFailureReason.unknown),
      );
      expect(talker.history, hasLength(1));
    });
  });

  group('signUp', () {
    test('returns the created user', () async {
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(
        () => auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => credential);

      final result = await repository.signUp(email: email, password: password);

      expect(
        result,
        isA<Ok<AppUser>>().having((ok) => ok.value, 'value', appUser),
      );
    });

    test('maps an email already in use', () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        await repository.signUp(email: email, password: password),
        failsWith(AuthFailureReason.emailAlreadyInUse),
      );
    });
  });

  group('sendPasswordReset', () {
    test('succeeds', () async {
      when(() => auth.sendPasswordResetEmail(email: email))
          .thenAnswer((_) async {});

      expect(await repository.sendPasswordReset(email: email), isA<Ok<void>>());
    });

    test('AUTH-7: does not reveal that the address is unknown', () async {
      when(() => auth.sendPasswordResetEmail(email: email))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      expect(await repository.sendPasswordReset(email: email), isA<Ok<void>>());
    });

    test('maps other errors', () async {
      when(() => auth.sendPasswordResetEmail(email: email))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect(
        await repository.sendPasswordReset(email: email),
        failsWith(AuthFailureReason.network),
      );
    });
  });

  test('signOut signs out of Firebase', () async {
    when(auth.signOut).thenAnswer((_) async {});

    expect(await repository.signOut(), isA<Ok<void>>());
    verify(auth.signOut).called(1);
  });

  group('reauthenticate', () {
    test('uses the email of the current user', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => MockUserCredential());

      expect(
        await repository.reauthenticate(password: password),
        isA<Ok<void>>(),
      );
      final credential =
          verify(() => user.reauthenticateWithCredential(captureAny()))
                  .captured
                  .single
              as EmailAuthCredential;
      expect(credential.email, email);
      expect(credential.password, password);
    });

    test('maps a wrong password', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      expect(
        await repository.reauthenticate(password: password),
        failsWith(AuthFailureReason.invalidCredentials),
      );
    });

    test('fails without a signed-in user', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(
        await repository.reauthenticate(password: password),
        failsWith(AuthFailureReason.unknown),
      );
    });
  });

  group('deleteAccount', () {
    test('deletes the current user', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(user.delete).thenAnswer((_) async {});

      expect(await repository.deleteAccount(), isA<Ok<void>>());
      verify(user.delete).called(1);
    });

    test('maps a required recent login', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(user.delete)
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

      expect(
        await repository.deleteAccount(),
        failsWith(AuthFailureReason.requiresRecentLogin),
      );
    });
  });
}
