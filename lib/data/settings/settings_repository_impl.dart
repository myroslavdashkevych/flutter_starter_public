import 'package:flutter_starter/data/settings/data_source/settings_prefs_data_source.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/repository/settings_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(
    this._localDataSource,
    this._talker,
    @Named(SettingsRepositoryImpl.usageDataSharingDefaultName)
    this._usageDataSharingDefault,
  );

  final SettingsPrefsDataSource _localDataSource;
  final Talker _talker;
  final bool _usageDataSharingDefault;

  /// The DI name of the flavor's default for usage data sharing, used when
  /// nothing is stored and when loading fails (SET-6).
  static const usageDataSharingDefaultName = 'usageDataSharingDefault';

  @override
  Future<Result<AppSettings>> load() async {
    try {
      final theme = await _localDataSource.readTheme();
      final locale = await _localDataSource.readLocale();
      final usageDataSharing = await _localDataSource.readUsageDataSharing();
      return Ok(
        AppSettings(
          themePreference:
              ThemePreference.values.asNameMap()[theme] ??
              ThemePreference.system,
          localePreference:
              LocalePreference.values.asNameMap()[locale] ??
              LocalePreference.system,
          usageDataSharing: usageDataSharing ?? _usageDataSharingDefault,
        ),
      );
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not load settings');
      return Ok(AppSettings(usageDataSharing: _usageDataSharingDefault));
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
