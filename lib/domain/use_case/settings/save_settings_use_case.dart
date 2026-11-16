import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/repository/settings_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SaveSettingsUseCase implements UseCase<void, ({AppSettings settings})> {
  SaveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call(({AppSettings settings}) params) =>
      _repository.save(params.settings);
}
