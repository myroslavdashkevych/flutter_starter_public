import 'package:flutter_starter/domain/_shared/base/use_case/stream_use_case.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Emits the device's registration ID (the Firebase Installation ID) when it
/// is assigned or changes.
@injectable
class WatchNotificationRegistrationIdsUseCase
    implements StreamUseCase<String, ()> {
  WatchNotificationRegistrationIdsUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Stream<String> call(() params) => _repository.registrationIdChanges();
}
