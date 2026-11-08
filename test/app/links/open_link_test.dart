import 'package:flutter/services.dart';
import 'package:flutter_starter/app/links/open_link.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  final url = Uri.parse('https://example.invalid/privacy');
  final talker = Talker();

  test(
    'SET-9: opens the in-app browser first and stops when it works',
    () async {
      final modes = <LaunchMode>[];

      final opened = await openLink(
        url,
        talker: talker,
        launch: (_, mode) async {
          modes.add(mode);
          return true;
        },
      );

      expect(opened, isTrue);
      expect(modes, [LaunchMode.inAppBrowserView]);
    },
  );

  test(
    'SET-9: falls back to an external browser when the in-app one fails',
    () async {
      final modes = <LaunchMode>[];

      final opened = await openLink(
        url,
        talker: talker,
        launch: (_, mode) async {
          modes.add(mode);
          return mode == LaunchMode.externalApplication;
        },
      );

      expect(opened, isTrue);
      expect(modes, [
        LaunchMode.inAppBrowserView,
        LaunchMode.externalApplication,
      ]);
    },
  );

  test(
    'falls back to an external browser when the in-app one throws',
    () async {
      final opened = await openLink(
        url,
        talker: talker,
        launch: (_, mode) async {
          if (mode == LaunchMode.inAppBrowserView) {
            throw PlatformException(code: 'failed');
          }
          return true;
        },
      );

      expect(opened, isTrue);
    },
  );

  test('SET-9: returns false when neither browser opens', () async {
    final opened = await openLink(
      url,
      talker: talker,
      launch: (_, _) async => false,
    );

    expect(opened, isFalse);
  });
}
