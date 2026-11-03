/// A local store of data that can be fetched again, such as API responses.
///
/// Local data is either a cache or user data (docs/architecture.md
/// section 5.6). Implement this only for a cache:
/// - losing a record costs a refetch, never user work;
/// - storage failures are logged and never reach the caller;
/// - records expire, and old schemas or unreadable records are deleted;
/// - it has its own box, named `<area>_cache`, never shared with user data.
///
/// Data the user created (favorites, notes, drafts) is user data: it is never
/// deleted automatically and must not implement this.
abstract interface class ExpiringCache {
  /// Deletes expired, outdated and unreadable records. Never throws.
  /// Runs after startup for every cache listed in `app/bootstrap.dart`.
  Future<void> evictExpired();
}
