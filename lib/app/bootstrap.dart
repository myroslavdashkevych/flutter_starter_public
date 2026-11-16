import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/firebase/firebase_options_dev.dart'
    as dev;
import 'package:flutter_starter/app/config/firebase/firebase_options_prod.dart'
    as prod;
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/locale_resolution.dart';
import 'package:flutter_starter/app/notification/background_handler.dart';
import 'package:flutter_starter/app/notification/notification_wiring.dart';
import 'package:flutter_starter/app/observability/crash_reporting_talker_observer.dart';
import 'package:flutter_starter/app/observability/crash_reporting_user_sync.dart';
import 'package:flutter_starter/app/observability/error_handler.dart';
import 'package:flutter_starter/app/observability/usage_data_collection.dart';
import 'package:flutter_starter/app/router/app_router.dart';
import 'package:flutter_starter/data/_shared/base/data_source/expiring_cache.dart';
import 'package:flutter_starter/data/_shared/data_source/hive/hive_init.dart';
import 'package:flutter_starter/data/character/data_source/character_hive_data_source.dart';
import 'package:flutter_starter/domain/_shared/service/crash_reporting/crash_reporting_service.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/initialize_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/register_for_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/show_foreground_notification_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_foreground_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_notification_registration_ids_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_opened_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/observability/set_crash_reporting_user_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/set_usage_data_collection_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_event.dart';
import 'package:material_ui/material_ui.dart';
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
  final settingsBloc = getIt<SettingsBloc>();
  await _setUpObservability(config, settingsBloc);
  await initHive();

  final packageInfo = await PackageInfo.fromPlatform();
  getIt.registerSingleton(
    AppInfo(version: '${packageInfo.version} (${packageInfo.buildNumber})'),
  );

  await _setUpNotifications();
  final router = createAppRouter(getIt<AuthBloc>());

  runApp(App(router: router, settingsBloc: settingsBloc));

  WidgetsBinding.instance.addPostFrameCallback((_) => _evictExpiredCaches());
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => openTappedNotifications(
      watchOpened: getIt<WatchOpenedNotificationsUseCase>(),
      router: router,
      talker: getIt<Talker>(),
    ),
  );
}

/// Lists every [ExpiringCache]; add a new cache here. User data never goes
/// here (doc/spec/architecture.md, Local storage).
Future<void> _evictExpiredCaches() async {
  final List<ExpiringCache> caches = [getIt<CharacterHiveDataSource>()];
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
    initialize: getIt<InitializeNotificationsUseCase>(),
    watchRegistrationIds: getIt<WatchNotificationRegistrationIdsUseCase>(),
    watchForeground: getIt<WatchForegroundNotificationsUseCase>(),
    showForeground: getIt<ShowForegroundNotificationUseCase>(),
    register: getIt<RegisterForNotificationsUseCase>(),
    talker: getIt<Talker>(),
    channelName: l10n.notificationChannelName,
  );
}

Future<void> _setUpObservability(
  AppConfig config,
  SettingsBloc settingsBloc,
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
  // The first frame uses them too (SET-4). Waiting for isLoaded, not for the
  // next state: Bloc skips a state equal to the current one.
  settingsBloc.add(const SettingsLoadRequested());
  await settingsBloc.stream.firstWhere((state) => state.isLoaded);
  await syncUsageDataCollection(
    settingsBloc: settingsBloc,
    collectionAllowed: config.flavor.collectsUsageData(isDebug: kDebugMode),
    setUsageDataCollection: getIt<SetUsageDataCollectionUseCase>(),
  );
  syncCrashReportingUser(
    watchAuthState: getIt<WatchAuthStateUseCase>(),
    setCrashReportingUser: getIt<SetCrashReportingUserUseCase>(),
  );
}
