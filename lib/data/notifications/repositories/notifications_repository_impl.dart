import 'package:flutter_starter/data/notifications/datasources/fcm_data_source.dart';
import 'package:flutter_starter/data/notifications/datasources/local_notifications_data_source.dart';
import 'package:flutter_starter/data/notifications/datasources/notifications_local_data_source.dart';
import 'package:flutter_starter/data/notifications/mappers/notification_message_mapper.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/notifications/entities/notification_message.dart';
import 'package:flutter_starter/domain/notifications/repositories/notifications_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(
    this._fcm,
    this._localNotifications,
    this._localDataSource,
    this._talker,
  );

  final FcmDataSource _fcm;
  final LocalNotificationsDataSource _localNotifications;
  final NotificationsLocalDataSource _localDataSource;
  final Talker _talker;

  @override
  Future<Result<void>> initialize({required String channelName}) => _guard(
    () => _localNotifications.initialize(channelName: channelName),
    'Could not initialize notifications',
    const Failure.unexpected(),
  );

  @override
  Future<Result<void>> register() async {
    try {
      await _fcm.register();
      return const Ok(null);
    } on Object catch (error, stackTrace) {
      // A warning, not a crash report: it fails on every launch without an APNs
      // key on iOS, and whenever the device has no network.
      _talker.warning(
        'Could not register for notifications',
        error,
        stackTrace,
      );
      return const Err(Failure.unexpected());
    }
  }

  @override
  Stream<String> registrationIdChanges() => _fcm.registrationIds;

  @override
  Future<Result<bool>> wasPermissionAsked() => _guard(
    _localDataSource.readPermissionRequested,
    'Could not read the notification permission flag',
    const Failure.cache(),
  );

  @override
  Future<Result<void>> markPermissionAsked() => _guard(
    _localDataSource.writePermissionRequested,
    'Could not save the notification permission flag',
    const Failure.cache(),
  );

  @override
  Future<Result<bool>> requestPermission() => _guard(
    _fcm.requestPermission,
    'Could not request the notification permission',
    const Failure.unexpected(),
  );

  @override
  Stream<NotificationMessage> foregroundMessages() =>
      _fcm.foregroundMessages.map((message) => message.toEntity());

  @override
  Future<Result<void>> showForeground(NotificationMessage message) => _guard(
    () => _localNotifications.show(
      title: message.title,
      body: message.body,
      route: message.route,
    ),
    'Could not show a notification',
    const Failure.unexpected(),
  );

  @override
  Stream<NotificationMessage> openedMessages() =>
      Stream.fromFuture(_launchMessage())
          .where((message) => message != null)
          .cast<NotificationMessage>()
          .mergeAll([
            _fcm.openedMessages.map((message) => message.toEntity()),
            _localNotifications.tappedRoutes.map(
              (route) => NotificationMessage(route: route),
            ),
          ]);

  Future<NotificationMessage?> _launchMessage() async {
    try {
      final remote = await _fcm.initialMessage();
      if (remote != null) return remote.toEntity();
      final route = await _localNotifications.launchRoute();
      return route == null ? null : NotificationMessage(route: route);
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not read the launch message');
      return null;
    }
  }

  Future<Result<T>> _guard<T>(
    Future<T> Function() call,
    String logMessage,
    Failure failure,
  ) async {
    try {
      return Ok(await call());
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, logMessage);
      return Err(failure);
    }
  }
}
