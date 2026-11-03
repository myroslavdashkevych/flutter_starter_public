import 'dart:ui';

/// Returns the first device locale with a supported language code, otherwise
/// the first supported locale, which is English.
Locale resolveDeviceLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supportedLocales,
) {
  for (final deviceLocale in deviceLocales ?? const <Locale>[]) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) return supported;
    }
  }
  return supportedLocales.first;
}
