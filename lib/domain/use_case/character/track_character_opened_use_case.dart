import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:injectable/injectable.dart';

/// Sends the character-opened event (CHR-18). The caller decides when: on opening,
/// not on a retry.
@injectable
class TrackCharacterOpenedUseCase
    implements UseCase<void, ({int characterId})> {
  TrackCharacterOpenedUseCase(this._analytics);

  final AnalyticsService _analytics;

  /// Analytics never fails the caller: the service logs its own failures.
  @override
  Future<Result<void>> call(({int characterId}) params) async {
    await _analytics.logEvent(
      AnalyticsEvent.characterOpened(characterId: params.characterId),
    );
    return const Ok(null);
  }
}
