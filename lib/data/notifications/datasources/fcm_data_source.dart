import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

/// Hides the static streams of [FirebaseMessaging] from the repository.
@lazySingleton
class FcmDataSource {
  FcmDataSource(this._messaging);

  final FirebaseMessaging _messaging;

  Stream<String> get registrationIds => _messaging.onRegistered;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<void> register() => _messaging.register();

  Future<RemoteMessage?> initialMessage() => _messaging.getInitialMessage();

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently ||
      AuthorizationStatus.notDetermined => false,
    };
  }
}
