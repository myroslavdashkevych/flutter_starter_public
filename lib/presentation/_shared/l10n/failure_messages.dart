import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';

extension FailureMessage on Failure {
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.failureNetwork,
    ServerFailure() => l10n.failureServer,
    NotFoundFailure() => l10n.failureNotFound,
    CacheFailure() => l10n.failureCache,
    UnexpectedFailure() => l10n.failureUnexpected,
    AuthFailure(:final reason) => switch (reason) {
      AuthFailureReason.invalidCredentials =>
        l10n.failureAuthInvalidCredentials,
      AuthFailureReason.emailAlreadyInUse => l10n.failureAuthEmailAlreadyInUse,
      AuthFailureReason.weakPassword => l10n.failureAuthWeakPassword,
      AuthFailureReason.invalidEmail => l10n.failureAuthInvalidEmail,
      AuthFailureReason.userDisabled => l10n.failureAuthUserDisabled,
      AuthFailureReason.tooManyRequests => l10n.failureAuthTooManyRequests,
      AuthFailureReason.requiresRecentLogin =>
        l10n.failureAuthRequiresRecentLogin,
      AuthFailureReason.network => l10n.failureNetwork,
      AuthFailureReason.unknown => l10n.failureUnexpected,
    },
  };
}
