import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(ignoreUnregisteredTypes: [AppConfig])
void configureDependencies(AppConfig config) {
  getIt.registerSingleton<AppConfig>(config);
  getIt.init(environment: config.flavor.name);
}
