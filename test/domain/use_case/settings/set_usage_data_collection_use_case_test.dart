import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/settings/set_usage_data_collection_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/fake_analytics_service.dart';
import '../../../helper/fake_crash_reporting_service.dart';

void main() {
  for (final enabled in [true, false]) {
    test('SET-7: switches analytics and crash reporting together '
        '($enabled)', () async {
      final crashReporting = FakeCrashReportingService();
      final analytics = FakeAnalyticsService();

      final result = await SetUsageDataCollectionUseCase(
        crashReporting,
        analytics,
      )((enabled: enabled));

      expect(result, isA<Ok<void>>());
      expect(crashReporting.collectionEnabled, enabled);
      expect(analytics.collectionEnabled, enabled);
    });
  }
}
