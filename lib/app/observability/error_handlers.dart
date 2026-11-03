import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_starter/domain/_shared/services/crash_reporting_service.dart';
import 'package:talker/talker.dart';

/// Reports uncaught errors directly. `talker.error` only adds them to the logs:
/// `CrashReportingTalkerObserver` ignores it, so each error is reported once.
void installErrorHandlers({
  required CrashReportingService crashReporting,
  required Talker talker,
}) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    talker.error('Flutter error', details.exception, details.stack);
    unawaited(
      crashReporting.recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString(),
        information: details.informationCollector?.call() ?? const [],
        fatal: true,
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    talker.error('Uncaught error', error, stackTrace);
    unawaited(crashReporting.recordError(error, stackTrace, fatal: true));
    return true;
  };
}
