import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_starter/data/_shared/network/auth_interceptor.dart';
import 'package:flutter_starter/data/_shared/network/retry_interceptor.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

/// Always returns [value] from [nextDouble].
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}

void main() {
  late FakeHttpClientAdapter adapter;
  late List<Duration> delays;

  setUp(() => delays = []);

  Dio createDio(
    ResponseBody Function(RequestOptions options) handler, {
    Future<void> Function(Duration)? delay,
  }) {
    adapter = FakeHttpClientAdapter(handler);
    final dio = Dio()..httpClientAdapter = adapter;
    return dio
      ..interceptors.add(
        RetryInterceptor(
          dio: dio,
          delay: delay ?? (duration) async => delays.add(duration),
          random: _FixedRandom(1),
        ),
      );
  }

  // Answers with [statuses] in order; the last one repeats.
  ResponseBody Function(RequestOptions) statuses(
    List<int> statuses, {
    Map<String, List<String>> headers = const {},
  }) {
    var index = 0;
    return (_) => ResponseBody.fromString(
      '{}',
      statuses[min(index++, statuses.length - 1)],
      headers: headers,
    );
  }

  for (final status in [408, 429, 502, 503, 504]) {
    test('retries a GET after $status', () async {
      final dio = createDio(statuses([status, 200]));

      final response = await dio.get<void>('/test');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
    });
  }

  test('retries a GET after a connection error', () async {
    var calls = 0;
    final dio = createDio((options) {
      if (calls++ == 0) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }
      return ResponseBody.fromString('{}', 200);
    });

    final response = await dio.get<void>('/test');

    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(2));
  });

  test('retries a HEAD request', () async {
    final dio = createDio(statuses([503, 200]));

    final response = await dio.head<void>('/test');

    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(2));
  });

  test('gives up after maxRetries with the last error', () async {
    final dio = createDio(statuses([503, 503, 504]));

    await expectLater(
      dio.get<void>('/test'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          504,
        ),
      ),
    );
    expect(adapter.requests, hasLength(1 + RetryInterceptor.maxRetries));
  });

  for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
    test('does not retry $method', () async {
      final dio = createDio(statuses([503, 200]));

      await expectLater(
        dio.request<void>('/test', options: Options(method: method)),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(1));
    });
  }

  for (final status in [400, 401, 404, 500]) {
    test('does not retry $status', () async {
      final dio = createDio(statuses([status, 200]));

      await expectLater(dio.get<void>('/test'), throwsA(isA<DioException>()));
      expect(adapter.requests, hasLength(1));
    });
  }

  test('does not retry timeouts', () async {
    final errors = [
      (RequestOptions options) => DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: options,
      ),
      (RequestOptions options) => DioException.receiveTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: options,
      ),
    ];
    for (final error in errors) {
      final dio = createDio((options) => throw error(options));

      await expectLater(dio.get<void>('/test'), throwsA(isA<DioException>()));
      expect(adapter.requests, hasLength(1));
    }
  });

  test('backs off exponentially', () async {
    final dio = createDio(statuses([503, 503, 200]));

    await dio.get<void>('/test');

    expect(delays, [
      RetryInterceptor.baseDelay,
      RetryInterceptor.baseDelay * 2,
    ]);
  });

  test('waits for a short Retry-After', () async {
    final dio = createDio(
      statuses(
        [429, 200],
        headers: {
          'retry-after': ['2'],
        },
      ),
    );

    final response = await dio.get<void>('/test');

    expect(response.statusCode, 200);
    expect(delays, [const Duration(seconds: 2)]);
  });

  Future<void> expectNoRetry(String retryAfter) async {
    final dio = createDio(
      statuses(
        [429, 200],
        headers: {
          'retry-after': [retryAfter],
        },
      ),
    );

    await expectLater(dio.get<void>('/test'), throwsA(isA<DioException>()));
    expect(adapter.requests, hasLength(1));
    expect(delays, isEmpty);
  }

  test(
    'ITM-8: does not retry a 429 with Retry-After "10"',
    () => expectNoRetry('10'),
  );

  for (final retryAfter in ['Wed, 21 Oct 2015 07:28:00 GMT', '-1']) {
    test(
      'does not retry with Retry-After "$retryAfter"',
      () => expectNoRetry(retryAfter),
    );
  }

  test('stops when the request is cancelled during the delay', () async {
    final cancelToken = CancelToken();
    final dio = createDio(
      statuses([503, 200]),
      delay: (_) async => cancelToken.cancel(),
    );

    await expectLater(
      dio.get<void>('/test', cancelToken: cancelToken),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('retries a request that AuthInterceptor refreshed', () async {
    final tokenProvider = _MockTokenProvider();
    var token = 'old';
    when(() => tokenProvider.getToken()).thenAnswer((_) async => token);
    when(() => tokenProvider.getToken(forceRefresh: true))
        .thenAnswer((_) async {
          token = 'new';
          return token;
        });
    final responses = statuses([401, 503, 200]);
    // AuthInterceptor changes the same RequestOptions, so record the header
    // when each request is sent.
    final sentTokens = <Object?>[];
    adapter = FakeHttpClientAdapter((options) {
      sentTokens.add(options.headers['authorization']);
      return responses(options);
    });
    final retryDio = Dio()..httpClientAdapter = adapter;
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider, retryDio: retryDio),
      RetryInterceptor(dio: dio, delay: (_) async {}, random: _FixedRandom(0)),
    ]);

    final response = await dio.get<void>('/test');

    expect(response.statusCode, 200);
    expect(sentTokens, ['Bearer old', 'Bearer new', 'Bearer new']);
    verifyNever(() => tokenProvider.onUnauthorized());
  });
}
