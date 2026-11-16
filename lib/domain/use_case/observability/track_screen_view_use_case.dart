import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:injectable/injectable.dart';

/// Sends `screen_view` with a route name that carries no ids (OBS-3).
@injectable
class TrackScreenViewUseCase implements UseCase<void, ({String name})> {
  TrackScreenViewUseCase(this._analytics);

  final AnalyticsService _analytics;

  /// Analytics never fails the caller: the service logs its own failures.
  @override
  Future<Result<void>> call(({String name}) params) async {
    await _analytics.logScreenView(params.name);
    return const Ok(null);
  }
}
