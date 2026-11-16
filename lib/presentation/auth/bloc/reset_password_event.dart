sealed class ResetPasswordEvent {
  const ResetPasswordEvent();
}

final class ResetPasswordSubmitted extends ResetPasswordEvent {
  const ResetPasswordSubmitted({required this.email});

  final String email;

  @override
  String toString() => 'ResetPasswordSubmitted(email: $email)';
}
