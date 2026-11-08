import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/firebase/firebase_options_dev.dart' as dev;
import 'package:flutter_starter/app/firebase/firebase_options_prod.dart'
    as prod;
import 'package:flutter_starter/app/locale_resolution.dart';
import 'package:flutter_starter/app/notifications/background_handler.dart';
import 'package:flutter_starter/app/notifications/notifications_wiring.dart';
import 'package:flutter_starter/app/observability/crash_reporting_talker_observer.dart';
import 'package:flutter_starter/app/observability/crash_reporting_user_sync.dart';
import 'package:flutter_starter/app/observability/error_handlers.dart';
import 'package:flutter_starter/app/observability/usage_data_collection.dart';
import 'package:flutter_starter/app/router/app_router.dart';
import 'package:flutter_starter/data/_shared/storage/expiring_cache.dart';
import 'package:flutter_starter/data/_shared/storage/hive_init.dart';
import 'package:flutter_starter/data/items/datasources/items_local_data_source.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/services/crash_reporting_service.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/notifications/repositories/notifications_repository.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment(Flavor.fromName(appFlavor));
  await Firebase.initializeApp(
    options: switch (config.flavor) {
      Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
      Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
    },
  );
  configureDependencies(config);
  final settingsCubit = getIt<SettingsCubit>();
  await _setUpObservability(config, settingsCubit);
  await initHive();

  final packageInfo = await PackageInfo.fromPlatform();
  getIt.registerSingleton(
    AppInfo(version: '${packageInfo.version} (${packageInfo.buildNumber})'),
  );

  await _setUpNotifications();
  final router = createAppRouter(getIt<AuthBloc>());

  runApp(App(router: router, settingsCubit: settingsCubit));

  WidgetsBinding.instance.addPostFrameCallback((_) => _evictExpiredCaches());
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => openTappedNotifications(
      repository: getIt<NotificationsRepository>(),
      router: router,
      talker: getIt<Talker>(),
    ),
  );
}

/// Lists every [ExpiringCache]; add a new cache here. User data never goes
/// here (docs/spec/architecture.md, Local storage).
Future<void> _evictExpiredCaches() async {
  final List<ExpiringCache> caches = [getIt<ItemsLocalDataSource>()];
  for (final cache in caches) {
    await cache.evictExpired();
  }
}

Future<void> _setUpNotifications() async {
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  // The system settings show the channel, so it follows the device language.
  final l10n = lookupAppLocalizations(
    resolveDeviceLocale(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );
  await setUpNotifications(
    repository: getIt<NotificationsRepository>(),
    talker: getIt<Talker>(),
    channelName: l10n.notificationChannelName,
  );
}

Future<void> _setUpObservability(
  AppConfig config,
  SettingsCubit settingsCubit,
) async {
  final talker = getIt<Talker>();
  final crashReporting = getIt<CrashReportingService>();
  talker.configure(observer: CrashReportingTalkerObserver(crashReporting));
  installErrorHandlers(crashReporting: crashReporting, talker: talker);
  Bloc.observer = TalkerBlocObserver(
    talker: talker,
    // States hold user data such as the email.
    settings: TalkerBlocLoggerSettings(enabled: config.flavor != Flavor.prod),
  );

  // Settings are loaded here because the first event needs the stored choice.
  await settingsCubit.load();
  await syncUsageDataCollection(
    settingsCubit: settingsCubit,
    collectionAllowed: config.flavor.collectsUsageData(isDebug: kDebugMode),
    crashReporting: crashReporting,
    analytics: getIt<AnalyticsService>(),
  );
  syncCrashReportingUser(
    authRepository: getIt<AuthRepository>(),
    crashReporting: crashReporting,
  );
}
