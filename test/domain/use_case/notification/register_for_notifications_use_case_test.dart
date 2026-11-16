import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/register_for_notifications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  test('registers through the repository', () async {
    final repository = _MockRepository();
    when(repository.register).thenAnswer((_) async => const Ok(null));

    final result = await RegisterForNotificationsUseCase(repository)(());

    expect(result, isA<Ok<void>>());
    verify(repository.register).called(1);
  });
}
