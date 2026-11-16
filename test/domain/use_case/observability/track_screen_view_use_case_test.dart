import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/observability/track_screen_view_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/fake_analytics_service.dart';

void main() {
  test('OBS-3: sends screen_view with the route name', () async {
    final analytics = FakeAnalyticsService();

    final result = await TrackScreenViewUseCase(analytics)((
      name: 'character_detail',
    ));

    expect(result, isA<Ok<void>>());
    expect(analytics.screens, ['character_detail']);
  });
}
