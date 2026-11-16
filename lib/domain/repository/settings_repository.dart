import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';

abstract interface class SettingsRepository {
  /// Never fails: unknown or missing values and a storage failure (logged) fall
  /// back to the defaults.
  Future<Result<AppSettings>> load();

  Future<Result<void>> save(AppSettings settings);
}
