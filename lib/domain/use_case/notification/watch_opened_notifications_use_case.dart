import 'package:flutter_starter/domain/_shared/base/use_case/stream_use_case.dart';
import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Emits the notifications the user taps, starting with the one that launched
/// the app (NTF-6).
@injectable
class WatchOpenedNotificationsUseCase
    implements StreamUseCase<NotificationMessage, ()> {
  WatchOpenedNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Stream<NotificationMessage> call(() params) => _repository.openedMessages();
}
