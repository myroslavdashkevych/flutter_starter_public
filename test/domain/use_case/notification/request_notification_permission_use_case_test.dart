import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/request_notification_permission_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/fake_notification_repository.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  late FakeNotificationRepository repository;
  late RequestNotificationPermissionUseCase useCase;

  setUp(() {
    repository = FakeNotificationRepository(asked: false);
    useCase = RequestNotificationPermissionUseCase(repository);
  });

  test(
    'NTF-2: "Allow" leads to the system request and sets the flag',
    () async {
      await useCase((agreed: true));

      expect(repository.permissionRequests, 1);
      expect(repository.asked, isTrue);
    },
  );

  test(
    'NTF-2, NTF-3: "Not now" sets the flag without the system request',
    () async {
      await useCase((agreed: false));

      expect(repository.permissionRequests, 0);
      expect(repository.asked, isTrue);
    },
  );

  test('sets the flag before the system request', () async {
    final mock = _MockRepository();
    when(mock.markPermissionAsked).thenAnswer((_) async => const Ok(null));
    when(mock.requestPermission).thenAnswer((_) async => const Ok(true));

    await RequestNotificationPermissionUseCase(mock)((agreed: true));

    verifyInOrder([mock.markPermissionAsked, mock.requestPermission]);
  });
}
