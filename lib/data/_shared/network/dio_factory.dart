import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_starter/data/_shared/network/auth_interceptor.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

const publicDioName = 'publicDio';
const backendDioName = 'backendDio';

/// Defaults for every request of both clients; a slow request overrides them
/// through its own `Options`.
const connectTimeout = Duration(seconds: 15);
const receiveTimeout = Duration(seconds: 30);

/// Client for third-party public APIs. It never sends an auth header.
Dio createPublicDio({
  required String baseUrl,
  required Talker talker,
  required bool logBodies,
}) =>
    Dio(_baseOptions(baseUrl))
      ..interceptors.add(createDioLogger(talker: talker, logBodies: logBodies));

/// Client for the app's own backend.
Dio createBackendDio({
  required String baseUrl,
  required TokenProvider tokenProvider,
  required Talker talker,
  required bool logBodies,
}) {
  final options = _baseOptions(baseUrl);
  final logger = createDioLogger(talker: talker, logBodies: logBodies);
  final retryDio = Dio(options)..interceptors.add(logger);
  return Dio(options)
    ..interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider, retryDio: retryDio),
      logger,
    ]);
}

TalkerDioLogger createDioLogger({
  required Talker talker,
  required bool logBodies,
}) => TalkerDioLogger(
  talker: talker,
  settings: TalkerDioLoggerSettings(
    hiddenHeaders: const {HttpHeaders.authorizationHeader},
    printRequestData: logBodies,
    printResponseData: logBodies,
    printErrorData: logBodies,
  ),
);

BaseOptions _baseOptions(String baseUrl) => BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: connectTimeout,
  receiveTimeout: receiveTimeout,
);
