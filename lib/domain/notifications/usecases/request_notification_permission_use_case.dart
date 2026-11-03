import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/notifications/repositories/notifications_repository.dart';
import 'package:injectable/injectable.dart';

/// Asks the user once per install. The system request comes only after the user
/// agrees in [call]'s `askUser`, because iOS shows that request a single time:
/// "Not now" must not use it up.
@injectable
class RequestNotificationPermissionUseCase {
  RequestNotificationPermissionUseCase(this._repository);

  final NotificationsRepository _repository;

  /// `askUser` returns whether the user agreed, or null when it could not ask;
  /// the user is then asked again next time.
  Future<void> call({required Future<bool?> Function() askUser}) async {
    final asked = await _repository.wasPermissionAsked();
    if (asked case Ok(value: true) || Err()) return;

    final agreed = await askUser();
    if (agreed == null) return;

    await _repository.markPermissionAsked();
    if (agreed) await _repository.requestPermission();
  }
}
