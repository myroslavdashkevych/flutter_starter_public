import 'dart:async';

import 'package:flutter_starter/domain/_shared/services/crash_reporting_service.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';

/// Keeps the user id of crash reports equal to the signed-in user.
StreamSubscription<AppUser?> syncCrashReportingUser({
  required AuthRepository authRepository,
  required CrashReportingService crashReporting,
}) => authRepository.authStateChanges().listen(
  (user) => unawaited(crashReporting.setUserId(user?.id)),
);
