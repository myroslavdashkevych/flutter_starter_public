sealed class SignInEvent {
  const SignInEvent();
}

final class SignInSubmitted extends SignInEvent {
  const SignInSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  /// Without the password: events are logged outside prod (OBS-7).
  @override
  String toString() => 'SignInSubmitted(email: $email)';
}
