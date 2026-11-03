abstract class TokenProvider {
  /// Returns the current token, or `null` when there is no signed-in user.
  Future<String?> getToken({bool forceRefresh = false});

  /// Called when the backend rejects a freshly refreshed token.
  Future<void> onUnauthorized();
}
