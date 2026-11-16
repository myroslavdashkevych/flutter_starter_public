import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/show_foreground_notification_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  test('shows the message through the repository', () async {
    const message = NotificationMessage(title: 'T', route: '/character-list/1');
    final repository = _MockRepository();
    registerFallbackValue(message);
    when(() => repository.showForeground(any()))
        .thenAnswer((_) async => const Ok(null));

    final result = await ShowForegroundNotificationUseCase(repository)((
      message: message,
    ));

    expect(result, isA<Ok<void>>());
    verify(() => repository.showForeground(message)).called(1);
  });
}
