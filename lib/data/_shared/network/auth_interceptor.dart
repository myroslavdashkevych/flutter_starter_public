import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';

/// Adds the bearer token and recovers from a 401 with one token refresh.
///
/// [retryDio] must not contain this interceptor: a failed retry would wait in
/// the error queue that the current `onError` call is holding.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this._tokenProvider, required this._retryDio});

  final TokenProvider _tokenProvider;
  final Dio _retryDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenProvider.getToken();
      if (token != null) {
        options.headers[HttpHeaders.authorizationHeader] = _bearer(token);
      }
      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != HttpStatus.unauthorized) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    try {
      final current = await _tokenProvider.getToken();
      // Another queued 401 may have refreshed the token already.
      final usedStaleToken =
          current != null &&
          options.headers[HttpHeaders.authorizationHeader] != _bearer(current);
      final token = usedStaleToken
          ? current
          : await _tokenProvider.getToken(forceRefresh: true);

      if (token == null) {
        await _tokenProvider.onUnauthorized();
        handler.next(err);
        return;
      }

      options.headers[HttpHeaders.authorizationHeader] = _bearer(token);
      handler.resolve(await _retryDio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == HttpStatus.unauthorized) {
        await _tokenProvider.onUnauthorized();
      }
      handler.next(retryError);
    } on Object catch (error, stackTrace) {
      handler.next(
        DioException(
          requestOptions: options,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  String _bearer(String token) => 'Bearer $token';
}
