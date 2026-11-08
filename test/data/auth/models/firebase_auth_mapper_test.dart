import 'package:flutter_starter/data/auth/models/firebase_auth_mapper.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  const expected = {
    'invalid-credential': AuthFailureReason.invalidCredentials,
    'wrong-password': AuthFailureReason.invalidCredentials,
    'user-not-found': AuthFailureReason.invalidCredentials,
    'email-already-in-use': AuthFailureReason.emailAlreadyInUse,
    'weak-password': AuthFailureReason.weakPassword,
    'invalid-email': AuthFailureReason.invalidEmail,
    'user-disabled': AuthFailureReason.userDisabled,
    'too-many-requests': AuthFailureReason.tooManyRequests,
    'requires-recent-login': AuthFailureReason.requiresRecentLogin,
    'network-request-failed': AuthFailureReason.network,
    'something-new': AuthFailureReason.unknown,
  };

  expected.forEach((code, reason) {
    test('AUTH-5: $code maps to ${reason.name}', () {
      expect(authFailureReasonFromCode(code), reason);
    });
  });

  test('AUTH-6: an unknown email and a wrong password give one reason', () {
    for (final code in [
      'invalid-credential',
      'user-not-found',
      'wrong-password',
    ]) {
      expect(
        authFailureReasonFromCode(code),
        AuthFailureReason.invalidCredentials,
        reason: code,
      );
    }
  });

  test('a Firebase user maps to AppUser', () {
    final user = MockFirebaseUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => user.email).thenReturn('user@example.com');

    expect(
      user.toEntity(),
      const AppUser(id: 'user-1', email: 'user@example.com'),
    );
  });
}
