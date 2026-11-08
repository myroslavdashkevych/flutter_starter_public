import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

/// Retries idempotent requests after transient failures.
///
/// Only GET and HEAD are retried: a POST whose response was lost may already
/// have been applied, and repeating it could apply it twice. Timeouts are not
/// retried because the user has already waited for them, and a 500 usually
/// means a server bug rather than a short outage.
///
/// The retry goes through [_dio] itself, so every attempt passes the other
/// interceptors again (a fresh auth token, logging).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this._dio,
    Future<void> Function(Duration)? delay,
    Random? random,
  }) : _delay = delay ?? Future<void>.delayed,
       _random = random ?? Random();

  static const maxRetries = 2;

  /// Upper bound of the first backoff; it doubles with every retry.
  static const baseDelay = Duration(milliseconds: 500);

  /// A longer `Retry-After` is not waited for: the user would see a loader
  /// for too long, so the error is shown and the user can retry by hand.
  static const maxRetryAfter = Duration(seconds: 3);

  static const _retryableMethods = {'GET', 'HEAD'};
  static const _retryableStatuses = {408, 429, 502, 503, 504};
  static const _attemptKey = 'retryAttempt';

  final Dio _dio;
  final Future<void> Function(Duration) _delay;
  final Random _random;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = options.extra[_attemptKey] as int? ?? 0;
    final delay = attempt < maxRetries && _isRetryable(err)
        ? _delayFor(err, attempt)
        : null;
    if (delay == null || _isCancelled(options)) {
      handler.next(err);
      return;
    }

    await _delay(delay);
    if (_isCancelled(options)) {
      handler.next(err);
      return;
    }

    try {
      final retry = options.copyWith(
        extra: {...options.extra, _attemptKey: attempt + 1},
      );
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      // The retry has already passed every interceptor, logging included.
      handler.reject(retryError);
    }
  }

  bool _isRetryable(DioException err) =>
      _retryableMethods.contains(err.requestOptions.method.toUpperCase()) &&
      switch (err.type) {
        DioExceptionType.connectionError => true,
        DioExceptionType.badResponse => _retryableStatuses.contains(
          err.response?.statusCode,
        ),
        _ => false,
      };

  /// Full-jitter exponential backoff, or the server's `Retry-After` in
  /// seconds. `null` means no retry: the header is too long or not a number
  /// of seconds (an HTTP date is usually a long wait).
  Duration? _delayFor(DioException err, int attempt) {
    final retryAfter = err.response?.headers.value(
      HttpHeaders.retryAfterHeader,
    );
    if (retryAfter == null) {
      return baseDelay * (1 << attempt) * _random.nextDouble();
    }
    final seconds = int.tryParse(retryAfter.trim());
    if (seconds == null || seconds < 0) return null;
    final wait = Duration(seconds: seconds);
    return wait <= maxRetryAfter ? wait : null;
  }

  bool _isCancelled(RequestOptions options) =>
      options.cancelToken?.isCancelled ?? false;
}
