import 'package:flutter_starter/data/settings/datasources/settings_local_data_source.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/domain/settings/repositories/settings_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

const usageDataSharingDefaultName = 'usageDataSharingDefault';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(
    this._localDataSource,
    this._talker,
    @Named(usageDataSharingDefaultName) this._usageDataSharingDefault,
  );

  final SettingsLocalDataSource _localDataSource;
  final Talker _talker;
  final bool _usageDataSharingDefault;

  @override
  Future<AppSettings> load() async {
    try {
      final theme = await _localDataSource.readTheme();
      final locale = await _localDataSource.readLocale();
      final usageDataSharing = await _localDataSource.readUsageDataSharing();
      return AppSettings(
        themePreference:
            ThemePreference.values.asNameMap()[theme] ?? ThemePreference.system,
        localePreference:
            LocalePreference.values.asNameMap()[locale] ??
            LocalePreference.system,
        usageDataSharing: usageDataSharing ?? _usageDataSharingDefault,
      );
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not load settings');
      return AppSettings(usageDataSharing: _usageDataSharingDefault);
    }
  }

  @override
  Future<Result<void>> save(AppSettings settings) async {
    try {
      await _localDataSource.writeTheme(settings.themePreference.name);
      await _localDataSource.writeLocale(settings.localePreference.name);
      await _localDataSource.writeUsageDataSharing(settings.usageDataSharing);
      return const Ok(null);
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not save settings');
      return const Err(Failure.cache());
    }
  }
}
