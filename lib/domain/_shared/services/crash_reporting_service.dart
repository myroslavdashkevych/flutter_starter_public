abstract class CrashReportingService {
  /// Turns sending crash reports on or off.
  Future<void> setCollectionEnabled(bool enabled);

  /// Links the next reports to [id]; null clears the link.
  Future<void> setUserId(String? id);

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  });
}
