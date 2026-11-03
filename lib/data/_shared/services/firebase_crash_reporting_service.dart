import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_starter/domain/_shared/services/crash_reporting_service.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// A failure to report is only logged: `talker.error` does not reach the crash
/// reporter, so it cannot loop.
@LazySingleton(as: CrashReportingService)
class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashReportingService(this._crashlytics, this._talker);

  final FirebaseCrashlytics _crashlytics;
  final Talker _talker;

  // Crashlytics applies `false` only from the next run of the app, so errors
  // are dropped here to stop reporting right away.
  bool _collectionEnabled = true;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    _collectionEnabled = enabled;
    return _guard(() async {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      // Reports stored while collection is off must not be sent if it is turned
      // on later.
      if (!enabled) await _crashlytics.deleteUnsentReports();
    });
  }

  // Crashlytics has no call to clear the identifier: an empty one replaces it.
  @override
  Future<void> setUserId(String? id) =>
      _guard(() => _crashlytics.setUserIdentifier(id ?? ''));

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (!_collectionEnabled) return;
    await _guard(
      () => _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        information: information,
        printDetails: false,
        fatal: fatal,
      ),
    );
  }

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on Object catch (error, stackTrace) {
      _talker.error('Could not reach Crashlytics', error, stackTrace);
    }
  }
}
