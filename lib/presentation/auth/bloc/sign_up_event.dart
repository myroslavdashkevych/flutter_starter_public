sealed class SignUpEvent {
  const SignUpEvent();
}

final class SignUpSubmitted extends SignUpEvent {
  const SignUpSubmitted({
    required this.email,
    required this.password,
    required this.confirmation,
  });

  final String email;
  final String password;
  final String confirmation;

  /// Without the password and its confirmation: events are logged outside
  /// prod (OBS-7).
  @override
  String toString() => 'SignUpSubmitted(email: $email)';
}
