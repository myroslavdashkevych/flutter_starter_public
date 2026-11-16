import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/character/track_character_opened_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/fake_analytics_service.dart';

void main() {
  test('CHR-18: sends select_content with the character id', () async {
    final analytics = FakeAnalyticsService();

    final result = await TrackCharacterOpenedUseCase(analytics)((
      characterId: 7,
    ));

    expect(result, isA<Ok<void>>());
    expect(analytics.events, [
      const AnalyticsEvent.characterOpened(characterId: 7),
    ]);
  });
}
