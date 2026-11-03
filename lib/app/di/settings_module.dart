import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/data/settings/repositories/settings_repository_impl.dart';
import 'package:injectable/injectable.dart';

@module
abstract class SettingsModule {
  @Named(usageDataSharingDefaultName)
  bool usageDataSharingDefault(AppConfig config) =>
      config.usageDataSharingDefault;
}
