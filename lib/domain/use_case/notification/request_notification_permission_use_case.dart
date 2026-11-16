import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:injectable/injectable.dart';

/// Records the user's answer to the notification dialog and, when they
/// agreed, makes the system request. The system request comes only after the
/// user agrees, because iOS shows it a single time: "Not now" must not use it
/// up (NTF-2, NTF-3).
@injectable
class RequestNotificationPermissionUseCase
    implements UseCase<void, ({bool agreed})> {
  RequestNotificationPermissionUseCase(this._repository);

  final NotificationRepository _repository;

  /// The repository logs its failures; a failed flag write still lets the
  /// system request run, as the user has answered.
  @override
  Future<Result<void>> call(({bool agreed}) params) async {
    await _repository.markPermissionAsked();
    if (params.agreed) await _repository.requestPermission();
    return const Ok(null);
  }
}
