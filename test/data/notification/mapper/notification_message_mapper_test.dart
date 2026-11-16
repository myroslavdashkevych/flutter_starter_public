import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_starter/data/notification/mapper/notification_message_mapper.dart';
import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the notification and the route', () {
    const message = RemoteMessage(
      notification: RemoteNotification(title: 'Title', body: 'Body'),
      data: {'route': '/character-list/1'},
    );

    expect(
      message.toEntity(),
      const NotificationMessage(
        title: 'Title',
        body: 'Body',
        route: '/character-list/1',
      ),
    );
  });

  test('a data message has no title or body', () {
    const message = RemoteMessage(data: {'other': 'value'});

    expect(message.toEntity(), const NotificationMessage());
  });

  test('a route that is not a string is ignored', () {
    const message = RemoteMessage(data: {'route': 1});

    expect(message.toEntity().route, isNull);
  });
}
