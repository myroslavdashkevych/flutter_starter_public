import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/crash_reporting/crash_reporting_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:injectable/injectable.dart';

/// Sets the user id of later crash reports; null clears it (OBS-2).
@injectable
class SetCrashReportingUserUseCase
    implements UseCase<void, ({String? userId})> {
  SetCrashReportingUserUseCase(this._crashReporting);

  final CrashReportingService _crashReporting;

  /// Crash reporting never fails the caller: the service logs its failures.
  @override
  Future<Result<void>> call(({String? userId}) params) async {
    await _crashReporting.setUserId(params.userId);
    return const Ok(null);
  }
}
