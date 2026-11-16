import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/observability/set_crash_reporting_user_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/fake_crash_reporting_service.dart';

void main() {
  test('OBS-2: sets the user id and clears it with null', () async {
    final crashReporting = FakeCrashReportingService();
    final useCase = SetCrashReportingUserUseCase(crashReporting);

    final set = await useCase((userId: 'user-1'));
    final cleared = await useCase((userId: null));

    expect(set, isA<Ok<void>>());
    expect(cleared, isA<Ok<void>>());
    expect(crashReporting.userIds, ['user-1', null]);
  });
}
