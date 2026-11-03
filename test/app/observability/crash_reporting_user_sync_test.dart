import 'dart:async';

import 'package:flutter_starter/app/observability/crash_reporting_user_sync.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fake_crash_reporting_service.dart';
import '../../helpers/mocks.dart';

void main() {
  test('sets the id after sign-in and clears it after sign-out', () async {
    final users = StreamController<AppUser?>();
    addTearDown(users.close);
    final repository = MockAuthRepository();
    when(repository.authStateChanges).thenAnswer((_) => users.stream);
    final crashReporting = FakeCrashReportingService();

    final subscription = syncCrashReportingUser(
      authRepository: repository,
      crashReporting: crashReporting,
    );
    addTearDown(subscription.cancel);
    users
      ..add(testUser)
      ..add(null);
    await Future<void>.delayed(Duration.zero);

    expect(crashReporting.userIds, [testUser.id, null]);
  });
}
