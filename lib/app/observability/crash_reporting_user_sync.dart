import 'dart:async';

import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/domain/use_case/observability/set_crash_reporting_user_use_case.dart';

/// Keeps the user id of crash reports equal to the signed-in user.
StreamSubscription<AppUser?> syncCrashReportingUser({
  required WatchAuthStateUseCase watchAuthState,
  required SetCrashReportingUserUseCase setCrashReportingUser,
}) =>
    watchAuthState(())
        .listen((user) => unawaited(setCrashReportingUser((userId: user?.id))));
