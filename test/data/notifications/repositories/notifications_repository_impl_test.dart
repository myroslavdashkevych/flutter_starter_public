import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_starter/data/notifications/datasources/fcm_data_source.dart';
import 'package:flutter_starter/data/notifications/datasources/local_notifications_data_source.dart';
import 'package:flutter_starter/data/notifications/datasources/notifications_local_data_source.dart';
import 'package:flutter_starter/data/notifications/repositories/notifications_repository_impl.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/notifications/entities/notification_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockFcm extends Mock implements FcmDataSource {}

class _MockLocalNotifications extends Mock
    implements LocalNotificationsDataSource {}

class _MockLocalDataSource extends Mock
    implements NotificationsLocalDataSource {}

Matcher _isErr(Failure failure) =>
    isA<Err<Object?>>().having((err) => err.failure, 'failure', failure);

void main() {
  late _MockFcm fcm;
  late _MockLocalNotifications localNotifications;
  late _MockLocalDataSource localDataSource;
  late StreamController<RemoteMessage> fcmOpened;
  late StreamController<String> localTaps;
  late Talker talker;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    fcm = _MockFcm();
    localNotifications = _MockLocalNotifications();
    localDataSource = _MockLocalDataSource();
    fcmOpened = StreamController.broadcast();
    localTaps = StreamController.broadcast();
    when(() => fcm.openedMessages).thenAnswer((_) => fcmOpened.stream);
    when(fcm.initialMessage).thenAnswer((_) async => null);
    when(() => localNotifications.tappedRoutes)
        .thenAnswer((_) => localTaps.stream);
    when(localNotifications.launchRoute).thenAnswer((_) async => null);
    repository = NotificationsRepositoryImpl(
      fcm,
      localNotifications,
      localDataSource,
      talker = Talker(),
    );
  });

  tearDown(() async {
    await fcmOpened.close();
    await localTaps.close();
  });

  group('openedMessages', () {
    test('emits an FCM tap and a local notification tap', () async {
      final messages = <NotificationMessage>[];
      final subscription = repository.openedMessages().listen(messages.add);
      await pumpEventQueue();

      fcmOpened.add(const RemoteMessage(data: {'route': '/items/1'}));
      localTaps.add('/items/2');
      await pumpEventQueue();

      expect(messages, const [
        NotificationMessage(route: '/items/1'),
        NotificationMessage(route: '/items/2'),
      ]);
      await subscription.cancel();
    });

    test('emits the FCM message that launched the app', () async {
      when(fcm.initialMessage).thenAnswer(
        (_) async => const RemoteMessage(data: {'route': '/items/1'}),
      );
      final messages = <NotificationMessage>[];
      final subscription = repository.openedMessages().listen(messages.add);
      await pumpEventQueue();

      expect(messages, const [NotificationMessage(route: '/items/1')]);
      await subscription.cancel();
    });

    test('emits the local notification that launched the app', () async {
      when(localNotifications.launchRoute).thenAnswer((_) async => '/items/2');
      final messages = <NotificationMessage>[];
      final subscription = repository.openedMessages().listen(messages.add);
      await pumpEventQueue();

      expect(messages, const [NotificationMessage(route: '/items/2')]);
      await subscription.cancel();
    });

    test('a failed launch lookup still delivers later taps', () async {
      when(fcm.initialMessage).thenThrow(Exception('channel'));
      final messages = <NotificationMessage>[];
      final subscription = repository.openedMessages().listen(messages.add);
      await pumpEventQueue();

      localTaps.add('/items/2');
      await pumpEventQueue();

      expect(messages, const [NotificationMessage(route: '/items/2')]);
      await subscription.cancel();
    });
  });

  test('showForeground passes the message to the local data source', () async {
    when(
      () => localNotifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
        route: any(named: 'route'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.showForeground(
      const NotificationMessage(title: 'T', body: 'B', route: '/items/1'),
    );

    expect(result, isA<Ok<void>>());
    verify(
      () => localNotifications.show(title: 'T', body: 'B', route: '/items/1'),
    ).called(1);
  });

  group('failures become Err', () {
    test('register, as a warning that is not a crash report', () async {
      when(fcm.register).thenThrow(Exception('no network'));

      expect(await repository.register(), _isErr(const Failure.unexpected()));
      expect(talker.history.single.logLevel, LogLevel.warning);
    });

    test('requestPermission', () async {
      when(fcm.requestPermission).thenThrow(Exception('channel'));

      expect(
        await repository.requestPermission(),
        _isErr(const Failure.unexpected()),
      );
    });

    test('the permission flag', () async {
      when(localDataSource.readPermissionRequested)
          .thenThrow(Exception('disk'));
      when(localDataSource.writePermissionRequested)
          .thenThrow(Exception('disk'));

      expect(
        await repository.wasPermissionAsked(),
        _isErr(const Failure.cache()),
      );
      expect(
        await repository.markPermissionAsked(),
        _isErr(const Failure.cache()),
      );
    });

    test('initialize', () async {
      when(
        () => localNotifications.initialize(
          channelName: any(named: 'channelName'),
        ),
      ).thenThrow(Exception('channel'));

      expect(
        await repository.initialize(channelName: 'General'),
        _isErr(const Failure.unexpected()),
      );
    });
  });
}
