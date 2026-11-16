import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';

extension AuthFieldErrorMessage on AuthFieldError {
  String message(AppLocalizations l10n) => switch (this) {
    AuthFieldError.emailEmpty => l10n.authEmailEmpty,
    AuthFieldError.emailInvalid => l10n.authEmailInvalid,
    AuthFieldError.passwordTooShort => l10n.authPasswordTooShort,
    AuthFieldError.passwordsDoNotMatch => l10n.authPasswordsDoNotMatch,
  };
}
