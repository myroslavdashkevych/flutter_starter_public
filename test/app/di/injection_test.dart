import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/data/_shared/data_source/network/dio_factory.dart';
import 'package:flutter_starter/data/_shared/data_source/network/token_provider.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker/talker.dart';

import '../../helper/mock.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class _MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class _MockLocalNotifications extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _MockSharedPreferences extends Mock implements SharedPreferencesAsync {}

void main() {
  const config = AppConfig(
    flavor: Flavor.dev,
    rickAndMortyApiBaseUrl: 'https://characters.invalid',
    backendBaseUrl: 'https://backend.invalid',
    characterCacheTtlMinutes: 30,
    privacyPolicyUrl: 'https://privacy.invalid',
    usageDataSharingDefault: true,
  );

  tearDown(() => getIt.reset());

  test('configureDependencies resolves every registration', () {
    // AuthBloc follows the auth state from its constructor.
    final firebaseAuth = MockFirebaseAuth();
    when(firebaseAuth.authStateChanges).thenAnswer((_) => const Stream.empty());

    configureDependencies(config);
    // The SDK objects need an initialized Firebase app or a platform plugin;
    // everything built on them is real.
    getIt
      ..unregister<FirebaseAuth>()
      ..registerSingleton<FirebaseAuth>(firebaseAuth)
      ..unregister<FirebaseAnalytics>()
      ..registerSingleton<FirebaseAnalytics>(_MockFirebaseAnalytics())
      ..unregister<FirebaseCrashlytics>()
      ..registerSingleton<FirebaseCrashlytics>(_MockFirebaseCrashlytics())
      ..unregister<FirebaseMessaging>()
      ..registerSingleton<FirebaseMessaging>(_MockFirebaseMessaging())
      ..unregister<FlutterLocalNotificationsPlugin>()
      ..registerSingleton<FlutterLocalNotificationsPlugin>(
        _MockLocalNotifications(),
      )
      ..unregister<SharedPreferencesAsync>()
      ..registerSingleton<SharedPreferencesAsync>(_MockSharedPreferences());

    // A missing registration or dependency throws here.
    final instances = getIt.findAll<Object>(
      instantiateLazySingletons: true,
      callFactories: true,
    );

    expect(instances, isNotEmpty);
  });

  test('configureDependencies registers AppConfig and Talker', () {
    configureDependencies(config);

    expect(getIt<AppConfig>(), same(config));
    expect(getIt<Talker>(), same(getIt<Talker>()));
  });

  test('configureDependencies registers the settings bloc', () {
    configureDependencies(config);

    expect(getIt.isRegistered<SettingsBloc>(), isTrue);
  });

  test('configureDependencies registers both Dio clients', () {
    configureDependencies(config);
    // The real implementation needs an initialized Firebase app.
    getIt
      ..unregister<TokenProvider>()
      ..registerSingleton<TokenProvider>(_MockTokenProvider());

    expect(
      getIt<Dio>(instanceName: publicDioName).options.baseUrl,
      config.rickAndMortyApiBaseUrl,
    );
    expect(
      getIt<Dio>(instanceName: backendDioName).options.baseUrl,
      config.backendBaseUrl,
    );
  });
}
