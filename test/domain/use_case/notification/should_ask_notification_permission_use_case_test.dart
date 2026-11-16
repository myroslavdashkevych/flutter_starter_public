import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/request_notification_permission_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/should_ask_notification_permission_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/fake_notification_repository.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  test('NTF-2: asks while the user has not answered', () async {
    final repository = FakeNotificationRepository(asked: false);

    final result = await ShouldAskNotificationPermissionUseCase(repository)(());

    expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue));
  });

  for (final agreed in [true, false]) {
    test('NTF-2: does not ask again after the answer "$agreed"', () async {
      final repository = FakeNotificationRepository(asked: false);
      await RequestNotificationPermissionUseCase(repository)((agreed: agreed));

      final result = await ShouldAskNotificationPermissionUseCase(repository)(
        (),
      );

      expect(
        result,
        isA<Ok<bool>>().having((ok) => ok.value, 'value', isFalse),
      );
    });
  }

  test('an unreadable flag is returned as the failure', () async {
    final mock = _MockRepository();
    when(mock.wasPermissionAsked)
        .thenAnswer((_) async => const Err(Failure.cache()));

    final result = await ShouldAskNotificationPermissionUseCase(mock)(());

    expect(result, isA<Err<bool>>());
  });
}
