import 'package:dio/dio.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/data/_shared/network/dio_factory.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  @Named(publicDioName)
  Dio publicDio(AppConfig config, Talker talker) => createPublicDio(
    baseUrl: config.itemsApiBaseUrl,
    talker: talker,
    logBodies: config.flavor != Flavor.prod,
  );

  @lazySingleton
  @Named(backendDioName)
  Dio backendDio(
    AppConfig config,
    TokenProvider tokenProvider,
    Talker talker,
  ) => createBackendDio(
    baseUrl: config.backendBaseUrl,
    tokenProvider: tokenProvider,
    talker: talker,
    logBodies: config.flavor != Flavor.prod,
  );
}
