import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';

abstract class SettingsRepository {
  /// Never fails: unreadable or unknown values fall back to the defaults.
  Future<AppSettings> load();

  Future<Result<void>> save(AppSettings settings);
}
