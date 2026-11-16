import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/service/crash_reporting/crash_reporting_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:injectable/injectable.dart';

/// Turns analytics and crash reporting on or off together (SET-7).
@injectable
class SetUsageDataCollectionUseCase implements UseCase<void, ({bool enabled})> {
  SetUsageDataCollectionUseCase(this._crashReporting, this._analytics);

  final CrashReportingService _crashReporting;
  final AnalyticsService _analytics;

  /// Never fails the caller: the services log their own failures.
  @override
  Future<Result<void>> call(({bool enabled}) params) async {
    await Future.wait([
      _crashReporting.setCollectionEnabled(params.enabled),
      _analytics.setCollectionEnabled(params.enabled),
    ]);
    return const Ok(null);
  }
}
