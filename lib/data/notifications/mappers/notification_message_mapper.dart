import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_starter/domain/notifications/entities/notification_message.dart';

extension RemoteMessageMapper on RemoteMessage {
  NotificationMessage toEntity() {
    final route = data['route'];
    return NotificationMessage(
      title: notification?.title,
      body: notification?.body,
      route: route is String ? route : null,
    );
  }
}
