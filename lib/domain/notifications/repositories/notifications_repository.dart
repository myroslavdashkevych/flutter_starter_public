import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/notifications/entities/notification_message.dart';

abstract class NotificationsRepository {
  /// Prepares showing foreground messages. [channelName] is the name the user
  /// sees for the notification channel in the system settings.
  Future<Result<void>> initialize({required String channelName});

  /// Registers this app instance for messages. The result arrives through
  /// [registrationIdChanges], so subscribe to it first.
  Future<Result<void>> register();

  /// Emits the Firebase Installation ID (FID) a backend sends messages to.
  Stream<String> registrationIdChanges();

  /// Whether the user has already been asked about notifications.
  Future<Result<bool>> wasPermissionAsked();

  Future<Result<void>> markPermissionAsked();

  /// Shows the system permission request. Returns whether it is granted.
  Future<Result<bool>> requestPermission();

  Stream<NotificationMessage> foregroundMessages();

  /// Shows a message that arrived while the app is in the foreground.
  Future<Result<void>> showForeground(NotificationMessage message);

  /// Taps on notifications, including the one that launched the app.
  Stream<NotificationMessage> openedMessages();
}
