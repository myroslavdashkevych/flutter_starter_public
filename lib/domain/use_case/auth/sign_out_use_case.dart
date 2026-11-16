import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignOutUseCase implements UseCase<void, ()> {
  SignOutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(() params) => _repository.signOut();
}
