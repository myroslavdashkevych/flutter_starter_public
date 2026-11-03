import 'dart:convert';
import 'dart:io';

import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromEnvironment keeps the flavor and defaults the cache TTL', () {
    final config = AppConfig.fromEnvironment(Flavor.prod);

    expect(config.flavor, Flavor.prod);
    expect(config.itemsCacheTtlMinutes, 30);
  });

  for (final file in ['config/dev.json', 'config/prod.json']) {
    test('$file defines every value AppConfig reads', () {
      final values =
          jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>;

      expect(values.keys, {
        'ITEMS_API_BASE_URL',
        'BACKEND_BASE_URL',
        'ITEMS_CACHE_TTL_MINUTES',
        'PRIVACY_POLICY_URL',
        'USAGE_DATA_SHARING_DEFAULT',
      });
    });
  }

  test('both flavors open the same privacy policy page', () {
    final urls = ['config/dev.json', 'config/prod.json'].map((file) {
      final values =
          jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>;
      return values['PRIVACY_POLICY_URL'];
    }).toSet();

    expect(urls, hasLength(1));
  });
}
