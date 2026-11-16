import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_foreground_notifications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  late _MockRepository repository;

  Future<List<NotificationMessage>> watch(List<NotificationMessage> incoming) {
    when(repository.foregroundMessages)
        .thenAnswer((_) => Stream.fromIterable(incoming));
    return WatchForegroundNotificationsUseCase(repository)(()).toList();
  }

  setUp(() => repository = _MockRepository());

  test('NTF-4: drops a message without title and body', () async {
    final messages = await watch([
      const NotificationMessage(route: '/character-list/1'),
    ]);

    expect(messages, isEmpty);
  });

  test('NTF-4: messages with a title or a body pass', () async {
    const withTitle = NotificationMessage(title: 'T');
    const withBody = NotificationMessage(body: 'B', route: '/character-list/1');
    const dataOnly = NotificationMessage(route: '/character-list/2');

    final messages = await watch([withTitle, dataOnly, withBody]);

    expect(messages, [withTitle, withBody]);
  });
}
