import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:injectable/injectable.dart';

/// Sends the search event with the term (CHR-17). The caller decides when:
/// after the debounce, for a non-empty term.
@injectable
class TrackSearchUseCase implements UseCase<void, ({String term})> {
  TrackSearchUseCase(this._analytics);

  final AnalyticsService _analytics;

  /// Analytics never fails the caller: the service logs its own failures.
  @override
  Future<Result<void>> call(({String term}) params) async {
    await _analytics.logEvent(AnalyticsEvent.searched(term: params.term));
    return const Ok(null);
  }
}
