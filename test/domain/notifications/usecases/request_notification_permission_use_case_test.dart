import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/notifications/repositories/notifications_repository.dart';
import 'package:flutter_starter/domain/notifications/usecases/request_notification_permission_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_notifications_repository.dart';

class _MockRepository extends Mock implements NotificationsRepository {}

void main() {
  late FakeNotificationsRepository repository;
  late RequestNotificationPermissionUseCase useCase;
  late int prompts;

  Future<bool?> Function() answering(bool? answer) => () async {
    prompts++;
    return answer;
  };

  setUp(() {
    repository = FakeNotificationsRepository(asked: false);
    useCase = RequestNotificationPermissionUseCase(repository);
    prompts = 0;
  });

  test('"Allow" leads to the system request and sets the flag', () async {
    await useCase(askUser: answering(true));

    expect(prompts, 1);
    expect(repository.permissionRequests, 1);
    expect(repository.asked, isTrue);
  });

  test('"Not now" sets the flag without the system request', () async {
    await useCase(askUser: answering(false));

    expect(prompts, 1);
    expect(repository.permissionRequests, 0);
    expect(repository.asked, isTrue);
  });

  test('does not ask again after any answer', () async {
    await useCase(askUser: answering(false));
    await useCase(askUser: answering(true));

    expect(prompts, 1);
    expect(repository.permissionRequests, 0);
  });

  test('a dialog that could not be shown leaves the flag unset', () async {
    await useCase(askUser: answering(null));

    expect(repository.permissionRequests, 0);
    expect(repository.asked, isFalse);
  });

  test('sets the flag before the system request', () async {
    final mock = _MockRepository();
    when(mock.wasPermissionAsked).thenAnswer((_) async => const Ok(false));
    when(mock.markPermissionAsked).thenAnswer((_) async => const Ok(null));
    when(mock.requestPermission).thenAnswer((_) async => const Ok(true));

    await RequestNotificationPermissionUseCase(mock)(askUser: () async => true);

    verifyInOrder([mock.markPermissionAsked, mock.requestPermission]);
  });

  test('an unreadable flag does not show the dialog', () async {
    final mock = _MockRepository();
    when(mock.wasPermissionAsked)
        .thenAnswer((_) async => const Err(Failure.cache()));

    await RequestNotificationPermissionUseCase(mock)(askUser: answering(true));

    expect(prompts, 0);
    verifyNever(mock.requestPermission);
  });
}
