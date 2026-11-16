sealed class FavoriteListEvent {
  const FavoriteListEvent();
}

/// Starts following the user and the favorites; added once by the
/// constructor.
final class FavoriteListStarted extends FavoriteListEvent {
  const FavoriteListStarted();
}

/// Removes by id, for a screen that could not load the character itself.
final class FavoriteListRemoveRequested extends FavoriteListEvent {
  const FavoriteListRemoveRequested(this.id);

  final int id;
}
