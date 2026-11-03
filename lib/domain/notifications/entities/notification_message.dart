import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_message.freezed.dart';

@freezed
abstract class NotificationMessage with _$NotificationMessage {
  const factory NotificationMessage({
    String? title,
    String? body,

    /// In-app location to open on a tap, for example `/items/1`.
    String? route,
  }) = _NotificationMessage;
}
