import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Registers the device for push notifications (NTF-5).
@injectable
class RegisterForNotificationsUseCase implements UseCase<void, ()> {
  RegisterForNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Result<void>> call(() params) => _repository.register();
}
