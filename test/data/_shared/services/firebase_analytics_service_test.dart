import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_starter/data/_shared/services/firebase_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late _MockFirebaseAnalytics analytics;
  late Talker talker;
  late FirebaseAnalyticsService service;

  setUp(() {
    analytics = _MockFirebaseAnalytics();
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    service = FirebaseAnalyticsService(analytics, talker);
  });

  test('setCollectionEnabled reaches the SDK', () async {
    when(() => analytics.setAnalyticsCollectionEnabled(false))
        .thenAnswer((_) async {});

    await service.setCollectionEnabled(false);

    verify(() => analytics.setAnalyticsCollectionEnabled(false)).called(1);
  });

  test('OBS-5: logEvent sends the name and parameters', () async {
    when(() => analytics.logEvent(name: 'login', parameters: {'method': 'x'}))
        .thenAnswer((_) async {});

    await service.logEvent('login', parameters: {'method': 'x'});

    verify(() => analytics.logEvent(name: 'login', parameters: {'method': 'x'}))
        .called(1);
  });

  test('logScreenView sends the screen name', () async {
    when(() => analytics.logScreenView(screenName: 'items'))
        .thenAnswer((_) async {});

    await service.logScreenView('items');

    verify(() => analytics.logScreenView(screenName: 'items')).called(1);
  });

  test('a failure is logged and does not reach the caller', () async {
    when(() => analytics.logEvent(name: 'login'))
        .thenThrow(Exception('offline'));

    await service.logEvent('login');

    expect(talker.history, hasLength(1));
  });
}
