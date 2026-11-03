import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/data/auth/models/firebase_auth_mapper.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._talker);

  final FirebaseAuth _auth;
  final Talker _talker;

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map((user) => user?.toEntity());

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.toEntity();
  });

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.toEntity();
  });

  @override
  Future<Result<void>> sendPasswordReset({required String email}) =>
      _guard(() async {
        try {
          await _auth.sendPasswordResetEmail(email: email);
        } on FirebaseAuthException catch (error) {
          // The page must not reveal whether the address exists.
          if (error.code != 'user-not-found') rethrow;
        }
      });

  @override
  Future<Result<void>> signOut() => _guard(_auth.signOut);

  @override
  Future<Result<void>> reauthenticate({required String password}) =>
      _guard(() async {
        final user = _auth.currentUser!;
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      });

  @override
  Future<Result<void>> deleteAccount() =>
      _guard(() => _auth.currentUser!.delete());

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on FirebaseAuthException catch (error, stackTrace) {
      final reason = authFailureReasonFromCode(error.code);
      if (reason == AuthFailureReason.unknown) {
        _talker.handle(error, stackTrace, 'Unexpected auth error');
      }
      return Err(Failure.auth(reason));
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Unexpected auth error');
      return const Err(Failure.auth(AuthFailureReason.unknown));
    }
  }
}
