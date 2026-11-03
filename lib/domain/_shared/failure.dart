import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  userDisabled,
  tooManyRequests,
  requiresRecentLogin,
  network,
  unknown,
}

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network() = NetworkFailure;

  const factory Failure.server(int? statusCode) = ServerFailure;

  const factory Failure.notFound() = NotFoundFailure;

  const factory Failure.cache() = CacheFailure;

  const factory Failure.auth(AuthFailureReason reason) = AuthFailure;

  const factory Failure.unexpected() = UnexpectedFailure;
}
