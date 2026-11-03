enum AuthFieldError {
  emailEmpty,
  emailInvalid,
  passwordTooShort,
  passwordsDoNotMatch,
}

final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Firebase's default password policy.
const _minPasswordLength = 6;

AuthFieldError? validateEmail(String email) {
  if (email.isEmpty) return AuthFieldError.emailEmpty;
  if (!_emailFormat.hasMatch(email)) return AuthFieldError.emailInvalid;
  return null;
}

AuthFieldError? validatePassword(String password) =>
    password.length < _minPasswordLength
    ? AuthFieldError.passwordTooShort
    : null;

AuthFieldError? validateConfirmation(String password, String confirmation) =>
    password == confirmation ? null : AuthFieldError.passwordsDoNotMatch;
