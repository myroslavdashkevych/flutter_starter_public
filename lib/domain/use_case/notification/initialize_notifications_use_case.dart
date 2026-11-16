import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Prepares showing notifications in the foreground on the given channel
/// (NTF-4).
@injectable
class InitializeNotificationsUseCase
    implements UseCase<void, ({String channelName})> {
  InitializeNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Result<void>> call(({String channelName}) params) =>
      _repository.initialize(channelName: params.channelName);
}
