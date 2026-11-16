import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';

abstract interface class AnalyticsService {
  /// Turns sending analytics data on or off.
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> logEvent(AnalyticsEvent event);

  Future<void> logScreenView(String name);
}
