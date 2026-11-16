import 'package:url_launcher/url_launcher.dart';

typedef LaunchLink = Future<bool> Function(Uri url, LaunchMode mode);
