import 'package:flutter_starter/domain/_shared/services/crash_reporting_service.dart';

/// Records what is sent, in order.
class FakeCrashReportingService implements CrashReportingService {
  final reports = <({Object error, String? reason, bool fatal})>[];
  final userIds = <String?>[];
  bool? collectionEnabled;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> setUserId(String? id) async => userIds.add(id);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    reports.add((error: error, reason: reason, fatal: fatal));
  }
}
