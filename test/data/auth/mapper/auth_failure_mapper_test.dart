import 'package:flutter_starter/data/auth/mapper/auth_failure_mapper.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expected = {
    'invalid-credential': Failure.auth(AuthFailureReason.invalidCredentials),
    'wrong-password': Failure.auth(AuthFailureReason.invalidCredentials),
    'user-not-found': Failure.auth(AuthFailureReason.invalidCredentials),
    'email-already-in-use': Failure.auth(AuthFailureReason.emailAlreadyInUse),
    'weak-password': Failure.auth(AuthFailureReason.weakPassword),
    'invalid-email': Failure.auth(AuthFailureReason.invalidEmail),
    'user-disabled': Failure.auth(AuthFailureReason.userDisabled),
    'too-many-requests': Failure.auth(AuthFailureReason.tooManyRequests),
    'requires-recent-login': Failure.auth(
      AuthFailureReason.requiresRecentLogin,
    ),
    'network-request-failed': Failure.network(),
    'something-new': Failure.auth(AuthFailureReason.unknown),
  };

  expected.forEach((code, failure) {
    test('AUTH-5: $code maps to $failure', () {
      expect(authFailureFromCode(code), failure);
    });
  });

  test('AUTH-6: an unknown email and a wrong password give one failure', () {
    for (final code in [
      'invalid-credential',
      'user-not-found',
      'wrong-password',
    ]) {
      expect(
        authFailureFromCode(code),
        const Failure.auth(AuthFailureReason.invalidCredentials),
        reason: code,
      );
    }
  });
}
