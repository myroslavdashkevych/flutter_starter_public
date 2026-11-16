import 'package:flutter_starter/app/config/flavor.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.rickAndMortyApiBaseUrl,
    required this.backendBaseUrl,
    required this.characterCacheTtlMinutes,
    required this.privacyPolicyUrl,
    required this.usageDataSharingDefault,
  });

  /// Reads the values passed with `--dart-define-from-file`.
  factory AppConfig.fromEnvironment(Flavor flavor) => AppConfig(
    flavor: flavor,
    rickAndMortyApiBaseUrl: const String.fromEnvironment(
      'RICK_AND_MORTY_API_BASE_URL',
    ),
    backendBaseUrl: const String.fromEnvironment('BACKEND_BASE_URL'),
    characterCacheTtlMinutes: const int.fromEnvironment(
      'CHARACTER_CACHE_TTL_MINUTES',
      defaultValue: 30,
    ),
    privacyPolicyUrl: const String.fromEnvironment('PRIVACY_POLICY_URL'),
    usageDataSharingDefault: const bool.fromEnvironment(
      'USAGE_DATA_SHARING_DEFAULT',
    ),
  );

  final Flavor flavor;
  final String rickAndMortyApiBaseUrl;
  final String backendBaseUrl;
  final int characterCacheTtlMinutes;
  final String privacyPolicyUrl;
  final bool usageDataSharingDefault;
}
