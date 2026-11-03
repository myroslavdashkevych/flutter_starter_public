import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Runs in a separate isolate, where neither DI nor Hive is available. The system
/// shows notification messages itself, so there is nothing else to do here.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}
