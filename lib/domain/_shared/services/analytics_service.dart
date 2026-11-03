abstract class AnalyticsService {
  /// Turns sending analytics data on or off.
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  Future<void> logScreenView(String name);
}
