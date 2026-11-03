import 'dart:async';

import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/services/crash_reporting_service.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';

/// Applies the "Share usage data" setting now and on every change. Collection
/// runs only when [collectionAllowed] and the setting are both true.
Future<StreamSubscription<SettingsState>> syncUsageDataCollection({
  required SettingsCubit settingsCubit,
  required bool collectionAllowed,
  required CrashReportingService crashReporting,
  required AnalyticsService analytics,
}) async {
  Future<void> apply(bool sharing) {
    final enabled = collectionAllowed && sharing;
    return Future.wait([
      crashReporting.setCollectionEnabled(enabled),
      analytics.setCollectionEnabled(enabled),
    ]);
  }

  var current = settingsCubit.state.settings.usageDataSharing;
  await apply(current);
  return settingsCubit.stream.listen((state) {
    final sharing = state.settings.usageDataSharing;
    if (sharing == current) return;
    current = sharing;
    unawaited(apply(sharing));
  });
}
