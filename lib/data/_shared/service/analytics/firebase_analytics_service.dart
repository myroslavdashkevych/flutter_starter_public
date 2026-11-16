import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// A failure to send analytics is logged and never reaches the caller.
@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics, this._talker);

  final FirebaseAnalytics _analytics;
  final Talker _talker;

  /// Firebase event names and parameters: standard GA4 events where one fits.
  static (String, Map<String, Object>?) _toFirebase(AnalyticsEvent event) =>
      switch (event) {
        SignedInAnalyticsEvent() => ('login', {'method': 'password'}),
        SignedUpAnalyticsEvent() => ('sign_up', {'method': 'password'}),
        PasswordResetRequestedAnalyticsEvent() => (
          'password_reset_requested',
          null,
        ),
        SearchedAnalyticsEvent(:final term) => (
          'search',
          {'search_term': term},
        ),
        CharacterOpenedAnalyticsEvent(:final characterId) => (
          'select_content',
          {'content_type': 'character', 'item_id': '$characterId'},
        ),
        AccountDeletedAnalyticsEvent() => ('account_deleted', null),
        FavoriteAddedAnalyticsEvent(:final characterId) => (
          'add_to_wishlist',
          {'item_id': '$characterId'},
        ),
        FavoriteRemovedAnalyticsEvent(:final characterId) => (
          'remove_from_wishlist',
          {'item_id': '$characterId'},
        ),
      };

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _guard(() => _analytics.setAnalyticsCollectionEnabled(enabled));

  @override
  Future<void> logEvent(AnalyticsEvent event) {
    final (name, parameters) = _toFirebase(event);
    return _guard(
      () => _analytics.logEvent(name: name, parameters: parameters),
    );
  }

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
