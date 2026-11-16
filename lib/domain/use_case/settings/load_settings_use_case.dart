import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/repository/settings_repository.dart';
import 'package:injectable/injectable.dart';

/// Passes the result of the repository through. It never fails, because the
/// repository returns the defaults when the settings cannot be read (SET-6).
@injectable
class LoadSettingsUseCase implements UseCase<AppSettings, ()> {
  LoadSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<AppSettings>> call(() params) => _repository.load();
}
