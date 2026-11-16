import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_notification_registration_ids_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  test('emits what the repository emits', () async {
    final repository = _MockRepository();
    when(repository.registrationIdChanges)
        .thenAnswer((_) => Stream.fromIterable(['fid-1', 'fid-2']));

    final ids = await WatchNotificationRegistrationIdsUseCase(repository)(())
        .toList();

    expect(ids, ['fid-1', 'fid-2']);
  });
}
