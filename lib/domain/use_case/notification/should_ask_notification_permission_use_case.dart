import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Whether to ask the user about notifications: once per install (NTF-2).
/// When the flag cannot be read, the failure is returned and the caller does
/// not ask.
@injectable
class ShouldAskNotificationPermissionUseCase implements UseCase<bool, ()> {
  ShouldAskNotificationPermissionUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Result<bool>> call(() params) async =>
      switch (await _repository.wasPermissionAsked()) {
        Ok(value: final asked) => Ok(!asked),
        Err(:final failure) => Err(failure),
      };
}
