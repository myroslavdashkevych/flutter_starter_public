import 'package:dio/dio.dart';
import 'package:flutter_starter/data/_shared/network/auth_interceptor.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

void main() {
  late _MockTokenProvider tokenProvider;
  late FakeHttpClientAdapter adapter;
  late Dio dio;
  late String token;

  // Accepts only the token in [validToken]; `null` rejects everything.
  void acceptOnly(String? validToken) {
    adapter = FakeHttpClientAdapter((options) {
      final accepted = options.headers['authorization'] == 'Bearer $validToken';
      return ResponseBody.fromString('{}', accepted ? 200 : 401);
    });
    final retryDio = Dio()..httpClientAdapter = adapter;
    dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(tokenProvider: tokenProvider, retryDio: retryDio),
      );
  }

  setUp(() {
    token = 'old';
    tokenProvider = _MockTokenProvider();
    when(() => tokenProvider.getToken()).thenAnswer((_) async => token);
    when(() => tokenProvider.getToken(forceRefresh: true))
        .thenAnswer((_) async {
          token = 'new';
          return token;
        });
    when(() => tokenProvider.onUnauthorized()).thenAnswer((_) async {});
  });

  test('adds the bearer header to a request', () async {
    acceptOnly('old');

    final response = await dio.get<void>('/test');

    expect(response.statusCode, 200);
    expect(adapter.requests.single.headers['authorization'], 'Bearer old');
    verifyNever(() => tokenProvider.getToken(forceRefresh: true));
  });

  test('sends no header when there is no token', () async {
    when(() => tokenProvider.getToken()).thenAnswer((_) async => null);
    adapter = FakeHttpClientAdapter((_) => ResponseBody.fromString('{}', 200));
    dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(tokenProvider: tokenProvider, retryDio: Dio()),
      );

    await dio.get<void>('/test');

    expect(adapter.requests.single.headers, isNot(contains('authorization')));
  });

  test('refreshes once on 401 and retries with the new token', () async {
    acceptOnly('new');

    final response = await dio.get<void>('/test');

    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.headers['authorization'], 'Bearer new');
    verify(() => tokenProvider.getToken(forceRefresh: true)).called(1);
    verifyNever(() => tokenProvider.onUnauthorized());
  });

  test('signs out on the second 401', () async {
    acceptOnly(null);

    await expectLater(
      dio.get<void>('/test'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(adapter.requests, hasLength(2));
    verify(() => tokenProvider.getToken(forceRefresh: true)).called(1);
    verify(() => tokenProvider.onUnauthorized()).called(1);
  });

  test('signs out when a refresh returns no token', () async {
    acceptOnly(null);
    when(() => tokenProvider.getToken(forceRefresh: true))
        .thenAnswer((_) async => null);

    await expectLater(dio.get<void>('/test'), throwsA(isA<DioException>()));

    expect(adapter.requests, hasLength(1));
    verify(() => tokenProvider.onUnauthorized()).called(1);
  });

  test('parallel 401 responses refresh the token only once', () async {
    acceptOnly('new');

    final responses = await Future.wait([
      dio.get<void>('/a'),
      dio.get<void>('/b'),
      dio.get<void>('/c'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    verify(() => tokenProvider.getToken(forceRefresh: true)).called(1);
    verifyNever(() => tokenProvider.onUnauthorized());
  });

  test('passes errors other than 401 through without a refresh', () async {
    adapter = FakeHttpClientAdapter((_) => ResponseBody.fromString('{}', 500));
    dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(tokenProvider: tokenProvider, retryDio: Dio()),
      );

    await expectLater(dio.get<void>('/test'), throwsA(isA<DioException>()));

    expect(adapter.requests, hasLength(1));
    verifyNever(() => tokenProvider.getToken(forceRefresh: true));
  });
}
