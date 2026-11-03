import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_starter/app/observability/crash_reporting_talker_observer.dart';
import 'package:flutter_starter/app/observability/error_handlers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';

import '../../helpers/fake_crash_reporting_service.dart';

void main() {
  late FakeCrashReportingService crashReporting;
  late Talker talker;
  late FlutterExceptionHandler? previousFlutterHandler;
  late ErrorCallback? previousDispatcherHandler;
  late DebugPrintCallback previousDebugPrint;

  setUp(() {
    previousFlutterHandler = FlutterError.onError;
    previousDispatcherHandler = PlatformDispatcher.instance.onError;
    previousDebugPrint = debugPrint;
    debugPrint = (_, {wrapWidth}) {};
    crashReporting = FakeCrashReportingService();
    talker = Talker(
      observer: CrashReportingTalkerObserver(crashReporting),
      settings: TalkerSettings(useConsoleLogs: false),
    );
    installErrorHandlers(crashReporting: crashReporting, talker: talker);
  });

  tearDown(() {
    FlutterError.onError = previousFlutterHandler;
    PlatformDispatcher.instance.onError = previousDispatcherHandler;
    debugPrint = previousDebugPrint;
  });

  test('a Flutter error is reported once as fatal and logged', () {
    final error = StateError('boom');

    FlutterError.onError!(
      FlutterErrorDetails(exception: error, stack: StackTrace.current),
    );

    expect(crashReporting.reports, hasLength(1));
    expect(crashReporting.reports.single.error, same(error));
    expect(crashReporting.reports.single.fatal, isTrue);
    expect(talker.history, hasLength(1));
  });

  test('an uncaught error is reported once as fatal and handled', () {
    final error = StateError('boom');

    final handled = PlatformDispatcher.instance.onError!(
      error,
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(crashReporting.reports, hasLength(1));
    expect(crashReporting.reports.single.error, same(error));
    expect(crashReporting.reports.single.fatal, isTrue);
    expect(talker.history, hasLength(1));
  });
}
