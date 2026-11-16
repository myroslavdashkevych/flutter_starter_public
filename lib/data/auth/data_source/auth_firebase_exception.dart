import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';

/// A Firebase Auth error, translated by `AuthFirebaseDataSource` so that the
/// repository imports no SDK (doc/spec/architecture.md, Inside a data area).
class AuthFirebaseException implements Exception {
  const AuthFirebaseException(this.failure, {required this.code});

  final Failure failure;

  /// The Firebase error code, kept for the log.
  final String code;

  @override
  String toString() => 'AuthFirebaseException($code)';
}
