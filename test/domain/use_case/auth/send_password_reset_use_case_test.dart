import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/send_password_reset_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  const email = 'user@example.com';

  late MockAuthRepository repository;
  late FakeAnalyticsService analytics;
  late SendPasswordResetUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    analytics = FakeAnalyticsService();
    useCase = SendPasswordResetUseCase(repository, analytics);
  });

  test('AUTH-8: a successful request sends password_reset_requested', () async {
    when(() => repository.sendPasswordReset(email: email))
        .thenAnswer((_) async => const Ok(null));

    final result = await useCase((email: email));

    expect(result, isA<Ok<void>>());
    expect(analytics.events, [const AnalyticsEvent.passwordResetRequested()]);
  });

  test('AUTH-8: a failed request sends no event', () async {
    const failure = Failure.network();
    when(() => repository.sendPasswordReset(email: email))
        .thenAnswer((_) async => const Err(failure));

    final result = await useCase((email: email));

    expect(
      result,
      isA<Err<void>>().having((err) => err.failure, 'failure', failure),
    );
    expect(analytics.events, isEmpty);
  });
}
