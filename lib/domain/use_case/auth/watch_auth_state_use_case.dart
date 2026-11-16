import 'package:flutter_starter/domain/_shared/base/use_case/stream_use_case.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:injectable/injectable.dart';

/// Emits the signed-in user, or null for a guest, now and on every change.
@injectable
class WatchAuthStateUseCase implements StreamUseCase<AppUser?, ()> {
  WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Stream<AppUser?> call(() params) => _repository.authStateChanges();
}
