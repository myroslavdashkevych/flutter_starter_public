import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/initialize_notifications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotificationRepository {}

void main() {
  test('initializes the repository with the channel name', () async {
    final repository = _MockRepository();
    when(() => repository.initialize(channelName: any(named: 'channelName')))
        .thenAnswer((_) async => const Ok(null));

    final result = await InitializeNotificationsUseCase(repository)((
      channelName: 'General',
    ));

    expect(result, isA<Ok<void>>());
    verify(() => repository.initialize(channelName: 'General')).called(1);
  });
}
