import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';

/// The failure of a Firebase Auth error [code]. A network error is a
/// [NetworkFailure], like any other network error; the rest are [AuthFailure]s.
Failure authFailureFromCode(String code) => switch (code) {
  'network-request-failed' => const Failure.network(),
  _ => Failure.auth(_reasonFromCode(code)),
};

AuthFailureReason _reasonFromCode(String code) => switch (code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => AuthFailureReason.invalidCredentials,
  'email-already-in-use' => AuthFailureReason.emailAlreadyInUse,
  'weak-password' => AuthFailureReason.weakPassword,
  'invalid-email' => AuthFailureReason.invalidEmail,
  'user-disabled' => AuthFailureReason.userDisabled,
  'too-many-requests' => AuthFailureReason.tooManyRequests,
  'requires-recent-login' => AuthFailureReason.requiresRecentLogin,
  _ => AuthFailureReason.unknown,
};
