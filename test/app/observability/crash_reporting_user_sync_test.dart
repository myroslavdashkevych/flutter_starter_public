import 'dart:async';

import 'package:flutter_starter/app/observability/crash_reporting_user_sync.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/domain/use_case/observability/set_crash_reporting_user_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helper/auth_fixture.dart';
import '../../helper/fake_crash_reporting_service.dart';
import '../../helper/mock.dart';

void main() {
  test(
    'OBS-2: sets the id after sign-in and clears it after sign-out',
    () async {
      final users = StreamController<AppUser?>();
      addTearDown(users.close);
      final repository = MockAuthRepository();
      when(repository.authStateChanges).thenAnswer((_) => users.stream);
      final crashReporting = FakeCrashReportingService();

      final subscription = syncCrashReportingUser(
        watchAuthState: WatchAuthStateUseCase(repository),
        setCrashReportingUser: SetCrashReportingUserUseCase(crashReporting),
      );
      addTearDown(subscription.cancel);
      users
        ..add(testUser)
        ..add(null);
      await Future<void>.delayed(Duration.zero);

      expect(crashReporting.userIds, [testUser.id, null]);
    },
  );
}
