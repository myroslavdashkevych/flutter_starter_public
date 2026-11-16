import 'package:flutter_starter/data/auth/data_source/auth_firebase_data_source.dart';
import 'package:flutter_starter/data/auth/data_source/auth_firebase_exception.dart';
import 'package:flutter_starter/data/auth/mapper/app_user_mapper.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, this._talker);

  final AuthFirebaseDataSource _dataSource;
  final Talker _talker;

  @override
  Stream<AppUser?> authStateChanges() =>
      _dataSource.authStateChanges().map((user) => user?.toEntity());

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    final user = await _dataSource.signIn(email: email, password: password);
    return user.toEntity();
  });

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  }) => _guard(() async {
    final user = await _dataSource.signUp(email: email, password: password);
    return user.toEntity();
  });

  @override
  Future<Result<void>> sendPasswordReset({required String email}) =>
      _guard(() => _dataSource.sendPasswordReset(email: email));

  @override
  Future<Result<void>> signOut() => _guard(_dataSource.signOut);

  @override
  Future<Result<void>> reauthenticate({required String password}) =>
      _guard(() => _dataSource.reauthenticate(password: password));

  @override
  Future<Result<void>> deleteAccount() => _guard(_dataSource.deleteAccount);

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on AuthFirebaseException catch (error, stackTrace) {
      if (error.failure == const Failure.auth(AuthFailureReason.unknown)) {
        _talker.handle(error, stackTrace, 'Unexpected auth error');
      }
      return Err(error.failure);
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Unexpected auth error');
      return const Err(Failure.auth(AuthFailureReason.unknown));
    }
  }
}
