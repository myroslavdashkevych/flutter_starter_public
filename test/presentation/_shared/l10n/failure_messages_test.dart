import 'package:flutter/widgets.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final uk = lookupAppLocalizations(const Locale('uk'));

  final expectedEn = <Failure, String>{
    const Failure.network(): en.failureNetwork,
    const Failure.server(500): en.failureServer,
    const Failure.notFound(): en.failureNotFound,
    const Failure.cache(): en.failureCache,
    const Failure.unexpected(): en.failureUnexpected,
    const Failure.auth(AuthFailureReason.invalidCredentials):
        en.failureAuthInvalidCredentials,
    const Failure.auth(AuthFailureReason.emailAlreadyInUse):
        en.failureAuthEmailAlreadyInUse,
    const Failure.auth(AuthFailureReason.weakPassword):
        en.failureAuthWeakPassword,
    const Failure.auth(AuthFailureReason.invalidEmail):
        en.failureAuthInvalidEmail,
    const Failure.auth(AuthFailureReason.userDisabled):
        en.failureAuthUserDisabled,
    const Failure.auth(AuthFailureReason.tooManyRequests):
        en.failureAuthTooManyRequests,
    const Failure.auth(AuthFailureReason.requiresRecentLogin):
        en.failureAuthRequiresRecentLogin,
    const Failure.auth(AuthFailureReason.network): en.failureNetwork,
    const Failure.auth(AuthFailureReason.unknown): en.failureUnexpected,
  };

  expectedEn.forEach((failure, message) {
    test('maps $failure to its message', () {
      expect(failure.message(en), message);
    });
  });

  test('every auth failure reason has a test case', () {
    for (final reason in AuthFailureReason.values) {
      expect(expectedEn, contains(Failure.auth(reason)));
    }
  });

  test('messages are translated', () {
    expect(
      const Failure.network().message(uk),
      isNot(const Failure.network().message(en)),
    );
  });
}
