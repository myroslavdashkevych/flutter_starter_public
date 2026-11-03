import 'package:flutter_starter/app/config/flavor.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.itemsApiBaseUrl,
    required this.backendBaseUrl,
    required this.itemsCacheTtlMinutes,
    required this.privacyPolicyUrl,
    required this.usageDataSharingDefault,
  });

  /// Reads the values passed with `--dart-define-from-file`.
  factory AppConfig.fromEnvironment(Flavor flavor) => AppConfig(
    flavor: flavor,
    itemsApiBaseUrl: const String.fromEnvironment('ITEMS_API_BASE_URL'),
    backendBaseUrl: const String.fromEnvironment('BACKEND_BASE_URL'),
    itemsCacheTtlMinutes: const int.fromEnvironment(
      'ITEMS_CACHE_TTL_MINUTES',
      defaultValue: 30,
    ),
    privacyPolicyUrl: const String.fromEnvironment('PRIVACY_POLICY_URL'),
    usageDataSharingDefault: const bool.fromEnvironment(
      'USAGE_DATA_SHARING_DEFAULT',
    ),
  );

  final Flavor flavor;
  final String itemsApiBaseUrl;
  final String backendBaseUrl;
  final int itemsCacheTtlMinutes;
  final String privacyPolicyUrl;
  final bool usageDataSharingDefault;
}
