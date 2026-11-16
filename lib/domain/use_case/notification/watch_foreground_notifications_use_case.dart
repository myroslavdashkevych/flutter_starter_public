import 'package:flutter_starter/domain/_shared/base/use_case/stream_use_case.dart';
import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Emits the messages that arrive in the foreground and have text to show; a
/// data-only message is not shown (NTF-4).
@injectable
class WatchForegroundNotificationsUseCase
    implements StreamUseCase<NotificationMessage, ()> {
  WatchForegroundNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Stream<NotificationMessage> call(() params) => _repository
      .foregroundMessages()
      .where((message) => message.title != null || message.body != null);
}
