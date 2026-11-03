import 'package:dio/dio.dart';
import 'package:flutter_starter/data/_shared/network/safe_call.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';

void main() {
  late Talker talker;
  final requestOptions = RequestOptions(path: '/test');

  DioException dioException(DioExceptionType type, {int? statusCode}) =>
      DioException(
        requestOptions: requestOptions,
        type: type,
        response: statusCode == null
            ? null
            : Response<void>(
                requestOptions: requestOptions,
                statusCode: statusCode,
              ),
      );

  Future<Failure> failureOf(Object error) async {
    final result = await safeCall<int>(() async => throw error, talker: talker);
    return (result as Err<int>).failure;
  }

  setUp(() {
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
  });

  test('returns Ok with the value of a successful call', () async {
    final result = await safeCall(() async => 42, talker: talker);

    expect((result as Ok<int>).value, 42);
    expect(talker.history, isEmpty);
  });

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.transformTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('maps $type to NetworkFailure', () async {
      expect(await failureOf(dioException(type)), const Failure.network());
    });
  }

  test('maps a 404 response to NotFoundFailure', () async {
    final error = dioException(DioExceptionType.badResponse, statusCode: 404);

    expect(await failureOf(error), const Failure.notFound());
  });

  for (final statusCode in [401, 500]) {
    test('maps a $statusCode response to ServerFailure', () async {
      final error = dioException(
        DioExceptionType.badResponse,
        statusCode: statusCode,
      );

      expect(await failureOf(error), Failure.server(statusCode));
    });
  }

  for (final type in [
    DioExceptionType.badCertificate,
    DioExceptionType.cancel,
    DioExceptionType.unknown,
  ]) {
    test('maps $type to UnexpectedFailure and logs it', () async {
      expect(await failureOf(dioException(type)), const Failure.unexpected());
      expect(talker.history, hasLength(1));
    });
  }

  test('maps a non-Dio error to UnexpectedFailure and logs it', () async {
    expect(
      await failureOf(const FormatException('bad json')),
      const Failure.unexpected(),
    );
    expect(talker.history, hasLength(1));
  });
}
