import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';

/// Records what is sent, in order. An event is `[name, parameters]`, so that
/// `expect` compares it deeply.
class FakeAnalyticsService implements AnalyticsService {
  final events = <List<Object?>>[];
  final screens = <String>[];
  bool? collectionEnabled;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add([name, parameters]);
  }

  @override
  Future<void> logScreenView(String name) async {
    screens.add(name);
  }
}
