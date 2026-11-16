import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/data/_shared/data_source/network/token_provider.dart';
import 'package:flutter_starter/data/auth/data_source/auth_firebase_exception.dart';
import 'package:flutter_starter/data/auth/mapper/auth_failure_mapper.dart';
import 'package:injectable/injectable.dart';

/// The only class that calls `FirebaseAuth`. A `FirebaseAuthException` leaves it
/// as an [AuthFirebaseException] with the original stack trace; other errors
/// pass through.
///
/// Also the [TokenProvider] of `backendDio`, registered as such in
/// `auth_firebase_module.dart`.
@lazySingleton
class AuthFirebaseDataSource implements TokenProvider {
  AuthFirebaseDataSource(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User> signIn({required String email, required String password}) =>
      _translate(() async {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return credential.user!;
      });

  Future<User> signUp({required String email, required String password}) =>
      _translate(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        return credential.user!;
      });

  Future<void> sendPasswordReset({required String email}) =>
      _translate(() async {
        try {
          await _auth.sendPasswordResetEmail(email: email);
        } on FirebaseAuthException catch (error) {
          // The page must not reveal whether the address exists (AUTH-7).
          if (error.code != 'user-not-found') rethrow;
        }
      });

  Future<void> signOut() => _translate(_auth.signOut);

  Future<void> reauthenticate({required String password}) =>
      _translate(() async {
        final user = _auth.currentUser!;
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      });

  Future<void> deleteAccount() => _translate(() => _auth.currentUser!.delete());

  @override
  Future<String?> getToken({bool forceRefresh = false}) async =>
      _auth.currentUser?.getIdToken(forceRefresh);

  @override
  Future<void> onUnauthorized() => _auth.signOut();

  Future<T> _translate<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AuthFirebaseException(
          authFailureFromCode(error.code),
          code: error.code,
        ),
        stackTrace,
      );
    }
  }
}
