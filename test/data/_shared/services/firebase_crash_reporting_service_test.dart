import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_starter/data/_shared/services/firebase_crash_reporting_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late _MockFirebaseCrashlytics crashlytics;
  late Talker talker;
  late FirebaseCrashReportingService service;

  setUp(() {
    crashlytics = _MockFirebaseCrashlytics();
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    service = FirebaseCrashReportingService(crashlytics, talker);
  });

  void stubRecordError(Future<void> Function() answer) {
    when(
      () => crashlytics.recordError(
        any<Object>(),
        any(),
        reason: any<Object?>(named: 'reason'),
        information: any(named: 'information'),
        printDetails: any(named: 'printDetails'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) => answer());
  }

  setUpAll(() => registerFallbackValue(StackTrace.empty));

  test('setCollectionEnabled reaches the SDK', () async {
    when(() => crashlytics.setCrashlyticsCollectionEnabled(true))
        .thenAnswer((_) async {});

    await service.setCollectionEnabled(true);

    verify(() => crashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
  });

  group('with collection turned off', () {
    setUp(() {
      when(() => crashlytics.setCrashlyticsCollectionEnabled(false))
          .thenAnswer((_) async {});
      when(() => crashlytics.deleteUnsentReports()).thenAnswer((_) async {});
    });

    test('deletes the reports stored on the device', () async {
      await service.setCollectionEnabled(false);

      verifyInOrder([
        () => crashlytics.setCrashlyticsCollectionEnabled(false),
        () => crashlytics.deleteUnsentReports(),
      ]);
    });

    test('drops errors right away, and sends them once on again', () async {
      when(() => crashlytics.setCrashlyticsCollectionEnabled(true))
          .thenAnswer((_) async {});
      stubRecordError(() async {});

      await service.setCollectionEnabled(false);
      await service.recordError(StateError('dropped'), StackTrace.empty);
      verifyNever(
        () => crashlytics.recordError(
          any<Object>(),
          any(),
          reason: any<Object?>(named: 'reason'),
          information: any(named: 'information'),
          printDetails: any(named: 'printDetails'),
          fatal: any(named: 'fatal'),
        ),
      );

      await service.setCollectionEnabled(true);
      await service.recordError(StateError('sent'), StackTrace.empty);
      verify(
        () => crashlytics.recordError(
          any<Object>(),
          any(),
          reason: any<Object?>(named: 'reason'),
          information: any(named: 'information'),
          printDetails: any(named: 'printDetails'),
          fatal: any(named: 'fatal'),
        ),
      ).called(1);
    });
  });

  test('setUserId sets the id, and null clears it', () async {
    when(() => crashlytics.setUserIdentifier(any())).thenAnswer((_) async {});

    await service.setUserId('user-1');
    await service.setUserId(null);

    verifyInOrder([
      () => crashlytics.setUserIdentifier('user-1'),
      () => crashlytics.setUserIdentifier(''),
    ]);
  });

  test('recordError passes the error and the fatal flag', () async {
    stubRecordError(() async {});
    final error = StateError('boom');

    await service.recordError(
      error,
      StackTrace.empty,
      reason: 'While testing',
      fatal: true,
    );

    verify(
      () => crashlytics.recordError(
        error,
        StackTrace.empty,
        reason: 'While testing',
        printDetails: false,
        fatal: true,
      ),
    ).called(1);
  });

  test('a failure to report is only logged', () async {
    stubRecordError(() async => throw Exception('channel'));

    await service.recordError(StateError('boom'), StackTrace.empty);

    expect(talker.history, hasLength(1));
  });
}
