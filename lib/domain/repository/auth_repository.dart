import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';

abstract interface class AuthRepository {
  /// Emits the current user on listen, then every sign-in and sign-out.
  Stream<AppUser?> authStateChanges();

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  });

  Future<Result<void>> sendPasswordReset({required String email});

  Future<Result<void>> signOut();

  Future<Result<void>> reauthenticate({required String password});

  Future<Result<void>> deleteAccount();
}
