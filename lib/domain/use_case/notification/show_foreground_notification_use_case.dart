import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Shows a message that arrived while the app is in the foreground (NTF-4).
@injectable
class ShowForegroundNotificationUseCase
    implements UseCase<void, ({NotificationMessage message})> {
  ShowForegroundNotificationUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Result<void>> call(({NotificationMessage message}) params) =>
      _repository.showForeground(params.message);
}
