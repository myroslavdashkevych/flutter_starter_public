import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_starter/data/_shared/service/analytics/firebase_analytics_service.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
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
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> expectSent(
    AnalyticsEvent event,
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    await service.logEvent(event);

    verify(() => analytics.logEvent(name: name, parameters: parameters))
        .called(1);
  }

  test('setCollectionEnabled reaches the SDK', () async {
    when(() => analytics.setAnalyticsCollectionEnabled(false))
        .thenAnswer((_) async {});

    await service.setCollectionEnabled(false);

    verify(() => analytics.setAnalyticsCollectionEnabled(false)).called(1);
  });

  group('OBS-5: logEvent sends the Firebase name and parameters', () {
    test('AUTH-8: login, sign_up and password_reset_requested', () async {
      await expectSent(const AnalyticsEvent.signedIn(), 'login', {
        'method': 'password',
      });
      await expectSent(const AnalyticsEvent.signedUp(), 'sign_up', {
        'method': 'password',
      });
      await expectSent(
        const AnalyticsEvent.passwordResetRequested(),
        'password_reset_requested',
      );
    });

    test('CHR-17: search with the search term', () async {
      await expectSent(const AnalyticsEvent.searched(term: 'rick'), 'search', {
        'search_term': 'rick',
      });
    });

    test('CHR-18: select_content with the character', () async {
      await expectSent(
        const AnalyticsEvent.characterOpened(characterId: 5),
        'select_content',
        {'content_type': 'character', 'item_id': '5'},
      );
    });

    test('PRF-8: account_deleted', () async {
      await expectSent(
        const AnalyticsEvent.accountDeleted(),
        'account_deleted',
      );
    });

    test(
      'FAV-11: add_to_wishlist and remove_from_wishlist with the character id',
      () async {
        await expectSent(
          const AnalyticsEvent.favoriteAdded(characterId: 5),
          'add_to_wishlist',
          {'item_id': '5'},
        );
        await expectSent(
          const AnalyticsEvent.favoriteRemoved(characterId: 5),
          'remove_from_wishlist',
          {'item_id': '5'},
        );
      },
    );
  });

  test('logScreenView sends the screen name', () async {
    when(() => analytics.logScreenView(screenName: 'character_list'))
        .thenAnswer((_) async {});

    await service.logScreenView('character_list');

    verify(() => analytics.logScreenView(screenName: 'character_list'))
        .called(1);
  });

  test('a failure is logged and does not reach the caller', () async {
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenThrow(Exception('offline'));

    await service.logEvent(const AnalyticsEvent.signedIn());

    expect(talker.history, hasLength(1));
  });
}
