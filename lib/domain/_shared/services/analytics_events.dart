abstract final class AnalyticsEvents {
  static const login = 'login';
  static const signUp = 'sign_up';
  static const passwordResetRequested = 'password_reset_requested';
  static const search = 'search';
  static const selectContent = 'select_content';
  static const accountDeleted = 'account_deleted';
  static const addToWishlist = 'add_to_wishlist';
  static const removeFromWishlist = 'remove_from_wishlist';
}

abstract final class AnalyticsParams {
  static const method = 'method';
  static const searchTerm = 'search_term';
  static const contentType = 'content_type';
  static const itemId = 'item_id';
}

abstract final class AnalyticsValues {
  static const passwordMethod = 'password';
  static const itemContentType = 'item';
}
