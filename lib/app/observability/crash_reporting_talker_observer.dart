import 'dart:async';

import 'package:flutter_starter/domain/_shared/services/crash_reporting_service.dart';
import 'package:talker/talker.dart';

/// Forwards what `talker.handle` catches as non-fatal reports.
///
/// `onLog` stays empty, so `talker.error` is not forwarded. An error in a Bloc
/// handler goes through `talker.error` in `TalkerBlocObserver` and is then
/// rethrown to `PlatformDispatcher.onError`, which reports it.
class CrashReportingTalkerObserver extends TalkerObserver {
  const CrashReportingTalkerObserver(this._crashReporting);

  final CrashReportingService _crashReporting;

  @override
  void onError(TalkerError err) => unawaited(
    _crashReporting.recordError(
      err.error ?? err,
      err.stackTrace,
      reason: err.message,
    ),
  );

  @override
  void onException(TalkerException err) => unawaited(
    _crashReporting.recordError(
      err.exception ?? err,
      err.stackTrace,
      reason: err.message,
    ),
  );
}
