import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';

/// Keeps the permission flag in memory and counts the system requests.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({this.asked = true});

  bool asked;
  int permissionRequests = 0;

  @override
  Future<Result<void>> initialize({required String channelName}) async =>
      const Ok(null);

  @override
  Future<Result<void>> register() async => const Ok(null);

  @override
  Stream<String> registrationIdChanges() => const Stream.empty();

  @override
  Future<Result<bool>> wasPermissionAsked() async => Ok(asked);

  @override
  Future<Result<void>> markPermissionAsked() async {
    asked = true;
    return const Ok(null);
  }

  @override
  Future<Result<bool>> requestPermission() async {
    permissionRequests++;
    return const Ok(true);
  }

  @override
  Stream<NotificationMessage> foregroundMessages() => const Stream.empty();

  @override
  Future<Result<void>> showForeground(NotificationMessage message) async =>
      const Ok(null);

  @override
  Stream<NotificationMessage> openedMessages() => const Stream.empty();
}
