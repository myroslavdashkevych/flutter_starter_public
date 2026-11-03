import 'package:flutter/services.dart';
import 'package:talker/talker.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LaunchLink = Future<bool> Function(Uri url, LaunchMode mode);

/// Opens [url] in the in-app browser (Custom Tabs on Android, SFSafariViewController
/// on iOS), then in an external browser. Returns false when neither worked.
Future<bool> openLink(
  Uri url, {
  required Talker talker,
  LaunchLink launch = _launch,
}) async {
  for (final mode in const [
    LaunchMode.inAppBrowserView,
    LaunchMode.externalApplication,
  ]) {
    try {
      if (await launch(url, mode)) return true;
      talker.warning('Could not open $url with $mode');
    } on PlatformException catch (error, stackTrace) {
      talker.warning('Could not open $url with $mode', error, stackTrace);
    }
  }
  return false;
}

Future<bool> _launch(Uri url, LaunchMode mode) => launchUrl(url, mode: mode);
