import 'package:dio/dio.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:talker/talker.dart';

/// Runs [call] and converts every exception into a [Failure].
Future<Result<T>> safeCall<T>(
  Future<T> Function() call, {
  required Talker talker,
}) async {
  try {
    return Ok(await call());
  } on DioException catch (error, stackTrace) {
    final failure = _mapDioException(error);
    if (failure is UnexpectedFailure) {
      talker.handle(error, stackTrace, 'Unexpected network error');
    }
    return Err(failure);
  } on Object catch (error, stackTrace) {
    talker.handle(error, stackTrace, 'Unexpected error');
    return const Err(Failure.unexpected());
  }
}

Failure _mapDioException(DioException error) => switch (error.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout ||
  DioExceptionType.connectionError => const Failure.network(),
  DioExceptionType.badResponse => switch (error.response?.statusCode) {
    404 => const Failure.notFound(),
    final statusCode => Failure.server(statusCode),
  },
  DioExceptionType.badCertificate ||
  DioExceptionType.cancel ||
  DioExceptionType.unknown => const Failure.unexpected(),
};
