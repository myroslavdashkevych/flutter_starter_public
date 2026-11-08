import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NAV-8: no Android intent filter opens the app from a link', () {
    final manifests = Directory('android/app/src')
        .listSync()
        .whereType<Directory>()
        .map((dir) => File('${dir.path}/AndroidManifest.xml'))
        .where((file) => file.existsSync())
        .toList();

    // Only intent filters register deep links; a <queries> entry for VIEW,
    // as url_launcher may need, does not.
    final intentFilter = RegExp(r'<intent-filter[\s\S]*?</intent-filter>');

    expect(manifests, isNotEmpty);
    for (final manifest in manifests) {
      final filters = intentFilter
          .allMatches(manifest.readAsStringSync())
          .map((match) => match[0]!);
      expect(
        filters,
        everyElement(isNot(contains('android.intent.action.VIEW'))),
        reason: manifest.path,
      );
    }
  });

  test('NAV-8: no iOS URL scheme is registered', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, isNot(contains('CFBundleURLTypes')));
  });
}
