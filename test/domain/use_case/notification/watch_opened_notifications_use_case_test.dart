import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_opened_notifications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  test('emits what the repository emits', () async {
    const message = NotificationMessage(route: '/character-list/1');
    final repository = _MockRepository();
    when(repository.openedMessages)
        .thenAnswer((_) => Stream.fromIterable([message]));

    final messages = await WatchOpenedNotificationsUseCase(repository)(())
        .toList();

    expect(messages, [message]);
  });
}
