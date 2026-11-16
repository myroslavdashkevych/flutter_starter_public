sealed class AuthEvent {
  const AuthEvent();
}

/// Starts following the auth state; added once by the constructor.
final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}
