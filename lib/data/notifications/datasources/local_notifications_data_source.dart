import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Shows foreground messages on Android, where FCM does not show them itself.
/// Elsewhere every call does nothing, so iOS never gets a second permission
/// request from this plugin.
@lazySingleton
class LocalNotificationsDataSource {
  LocalNotificationsDataSource(this._plugin);

  /// Must match `default_notification_channel_id` in `AndroidManifest.xml`.
  static const channelId = 'general';

  final FlutterLocalNotificationsPlugin _plugin;
  final _tappedRoutes = StreamController<String>.broadcast();
  var _channelName = '';
  var _nextId = 0;

  bool get _isSupported => defaultTargetPlatform == TargetPlatform.android;

  Stream<String> get tappedRoutes => _tappedRoutes.stream;

  Future<void> initialize({required String channelName}) async {
    if (!_isSupported) return;
    _channelName = channelName;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload case final route?) _tappedRoutes.add(route);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.high,
          ),
        );
  }

  Future<void> show({String? title, String? body, String? route}) async {
    if (!_isSupported) return;
    await _plugin.show(
      id: _nextId++,
      title: title,
      body: body,
      payload: route,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// The route of the local notification that launched the app, if any.
  Future<String?> launchRoute() async {
    if (!_isSupported) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false
        ? details?.notificationResponse?.payload
        : null;
  }
}
