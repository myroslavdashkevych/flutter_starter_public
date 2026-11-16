import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';

/// Records what is sent, in order. Events compare by value, so `expect`
/// matches them directly.
class FakeAnalyticsService implements AnalyticsService {
  final events = <AnalyticsEvent>[];
  final screens = <String>[];
  bool? collectionEnabled;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    events.add(event);
  }

  @override
  Future<void> logScreenView(String name) async {
    screens.add(name);
  }
}
