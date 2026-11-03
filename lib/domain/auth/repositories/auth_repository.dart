import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';

abstract class AuthRepository {
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
