import 'package:dio/dio.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/data/_shared/network/dio_factory.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

void main() {
  tearDown(() => getIt.reset());

  test('configureDependencies registers AppConfig and Talker', () {
    const config = AppConfig(
      flavor: Flavor.dev,
      itemsApiBaseUrl: 'https://items.invalid',
      backendBaseUrl: 'https://backend.invalid',
      itemsCacheTtlMinutes: 30,
      privacyPolicyUrl: 'https://privacy.invalid',
      usageDataSharingDefault: true,
    );

    configureDependencies(config);

    expect(getIt<AppConfig>(), same(config));
    expect(getIt<Talker>(), same(getIt<Talker>()));
  });

  test('configureDependencies registers the settings cubit', () {
    const config = AppConfig(
      flavor: Flavor.dev,
      itemsApiBaseUrl: 'https://items.invalid',
      backendBaseUrl: 'https://backend.invalid',
      itemsCacheTtlMinutes: 30,
      privacyPolicyUrl: 'https://privacy.invalid',
      usageDataSharingDefault: true,
    );

    configureDependencies(config);

    expect(getIt.isRegistered<SettingsCubit>(), isTrue);
  });

  test('configureDependencies registers both Dio clients', () {
    const config = AppConfig(
      flavor: Flavor.dev,
      itemsApiBaseUrl: 'https://items.invalid',
      backendBaseUrl: 'https://backend.invalid',
      itemsCacheTtlMinutes: 30,
      privacyPolicyUrl: 'https://privacy.invalid',
      usageDataSharingDefault: true,
    );

    configureDependencies(config);
    // The real implementation needs an initialized Firebase app.
    getIt
      ..unregister<TokenProvider>()
      ..registerSingleton<TokenProvider>(_MockTokenProvider());

    expect(
      getIt<Dio>(instanceName: publicDioName).options.baseUrl,
      config.itemsApiBaseUrl,
    );
    expect(
      getIt<Dio>(instanceName: backendDioName).options.baseUrl,
      config.backendBaseUrl,
    );
  });
}
