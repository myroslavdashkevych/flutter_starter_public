sealed class ProfileEvent {
  const ProfileEvent();
}

/// Starts following the current user; added once by the constructor.
final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// An account action. They share one handler, so a second one is ignored
/// while one runs (PRF-9).
sealed class ProfileAction extends ProfileEvent {
  const ProfileAction();
}

final class ProfileSignOutRequested extends ProfileAction {
  const ProfileSignOutRequested();
}

final class ProfileDeleteRequested extends ProfileAction {
  const ProfileDeleteRequested({required this.password});

  final String password;

  /// Without the password: events are logged outside prod (OBS-7).
  @override
  String toString() => 'ProfileDeleteRequested()';
}
