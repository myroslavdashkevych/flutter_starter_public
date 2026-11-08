import 'dart:ui';

import 'package:flutter_starter/app/locale_resolution.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = AppLocalizations.supportedLocales;

  test('English is the first supported locale', () {
    expect(supported.first, const Locale('en'));
  });

  test('SET-3: returns the first device locale with a supported language', () {
    expect(
      resolveDeviceLocale(const [
        Locale('de'),
        Locale('uk', 'UA'),
        Locale('en'),
      ], supported),
      const Locale('uk'),
    );
  });

  test('SET-3: falls back to English for unsupported languages', () {
    expect(
      resolveDeviceLocale(const [Locale('de'), Locale('fr')], supported),
      const Locale('en'),
    );
  });

  test('falls back to English without device locales', () {
    expect(resolveDeviceLocale(null, supported), const Locale('en'));
    expect(resolveDeviceLocale(const [], supported), const Locale('en'));
  });
}
