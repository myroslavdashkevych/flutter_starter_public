import 'package:flutter_starter/data/_shared/network/auth_interceptor.dart';
import 'package:flutter_starter/data/_shared/network/dio_factory.dart';
import 'package:flutter_starter/data/_shared/network/retry_interceptor.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

void main() {
  final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));

  test('publicDio has no AuthInterceptor', () {
    final dio = createPublicDio(
      baseUrl: 'https://public.invalid',
      talker: talker,
      logBodies: true,
    );

    expect(dio.options.baseUrl, 'https://public.invalid');
    expect(dio.interceptors.whereType<AuthInterceptor>(), isEmpty);
  });

  test('publicDio has connect and receive timeouts', () {
    final dio = createPublicDio(
      baseUrl: 'https://public.invalid',
      talker: talker,
      logBodies: true,
    );

    expect(dio.options.connectTimeout, connectTimeout);
    expect(dio.options.receiveTimeout, receiveTimeout);
  });

  test('backendDio has one AuthInterceptor', () {
    final dio = createBackendDio(
      baseUrl: 'https://backend.invalid',
      tokenProvider: _MockTokenProvider(),
      talker: talker,
      logBodies: true,
    );

    expect(dio.options.baseUrl, 'https://backend.invalid');
    expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
  });

  test('publicDio retries after logging', () {
    final dio = createPublicDio(
      baseUrl: 'https://public.invalid',
      talker: talker,
      logBodies: true,
    );

    expect(dio.interceptors.whereType<RetryInterceptor>(), hasLength(1));
    expect(dio.interceptors.last, isA<RetryInterceptor>());
  });

  test('backendDio retries after the auth refresh and logging', () {
    final dio = createBackendDio(
      baseUrl: 'https://backend.invalid',
      tokenProvider: _MockTokenProvider(),
      talker: talker,
      logBodies: true,
    );
    final interceptors = dio.interceptors.toList();

    expect(interceptors.whereType<RetryInterceptor>(), hasLength(1));
    expect(interceptors.last, isA<RetryInterceptor>());
    expect(
      interceptors.indexWhere((i) => i is AuthInterceptor),
      lessThan(interceptors.length - 1),
    );
  });

  test('backendDio has connect and receive timeouts', () {
    final dio = createBackendDio(
      baseUrl: 'https://backend.invalid',
      tokenProvider: _MockTokenProvider(),
      talker: talker,
      logBodies: true,
    );

    expect(dio.options.connectTimeout, connectTimeout);
    expect(dio.options.receiveTimeout, receiveTimeout);
  });

  test('logger always hides the Authorization header', () {
    for (final logBodies in [true, false]) {
      final logger = createDioLogger(talker: talker, logBodies: logBodies);

      expect(logger.settings.hiddenHeaders, contains('authorization'));
    }
  });

  test('logger logs no bodies when logBodies is false', () {
    final settings = createDioLogger(talker: talker, logBodies: false).settings;

    expect(settings.printRequestData, isFalse);
    expect(settings.printResponseData, isFalse);
    expect(settings.printErrorData, isFalse);
  });
}
