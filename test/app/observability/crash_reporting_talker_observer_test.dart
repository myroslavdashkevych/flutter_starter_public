import 'package:flutter_starter/app/observability/crash_reporting_talker_observer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';

import '../../helpers/fake_crash_reporting_service.dart';

void main() {
  late FakeCrashReportingService crashReporting;
  late Talker talker;

  setUp(() {
    crashReporting = FakeCrashReportingService();
    talker = Talker(
      observer: CrashReportingTalkerObserver(crashReporting),
      settings: TalkerSettings(useConsoleLogs: false),
    );
  });

  test('OBS-1: talker.handle reports an exception as non-fatal', () {
    final exception = Exception('boom');

    talker.handle(exception, StackTrace.current, 'While testing');

    expect(crashReporting.reports, hasLength(1));
    final report = crashReporting.reports.single;
    expect(report.error, same(exception));
    expect(report.reason, 'While testing');
    expect(report.fatal, isFalse);
  });

  test('talker.handle reports an Error as non-fatal', () {
    final error = StateError('boom');

    talker.handle(error, StackTrace.current);

    expect(crashReporting.reports.single.error, same(error));
    expect(crashReporting.reports.single.fatal, isFalse);
  });

  test(
    'talker.error is not reported, so errors reported elsewhere stay single',
    () {
      talker.error('Bloc', StateError('boom'), StackTrace.current);

      expect(crashReporting.reports, isEmpty);
    },
  );
}
