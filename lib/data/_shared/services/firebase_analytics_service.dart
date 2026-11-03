import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// A failure to send analytics is logged and never reaches the caller.
@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics, this._talker);

  final FirebaseAnalytics _analytics;
  final Talker _talker;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _guard(() => _analytics.setAnalyticsCollectionEnabled(enabled));

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) =>
      _guard(() => _analytics.logEvent(name: name, parameters: parameters));

  @override
  Future<void> logScreenView(String name) =>
      _guard(() => _analytics.logScreenView(screenName: name));

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not send analytics');
    }
  }
}
