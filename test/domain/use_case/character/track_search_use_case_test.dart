import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/character/track_search_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/fake_analytics_service.dart';

void main() {
  test('CHR-17: sends search with the term', () async {
    final analytics = FakeAnalyticsService();

    final result = await TrackSearchUseCase(analytics)((term: 'rick'));

    expect(result, isA<Ok<void>>());
    expect(analytics.events, [const AnalyticsEvent.searched(term: 'rick')]);
  });
}
