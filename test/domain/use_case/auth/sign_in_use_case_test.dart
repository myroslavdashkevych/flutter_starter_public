import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_in_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret1';

  late MockAuthRepository repository;
  late FakeAnalyticsService analytics;
  late SignInUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    analytics = FakeAnalyticsService();
    useCase = SignInUseCase(repository, analytics);
  });

  test('AUTH-8: a successful sign-in sends login', () async {
    when(() => repository.signIn(email: email, password: password))
        .thenAnswer((_) async => const Ok(testUser));

    final result = await useCase((email: email, password: password));

    expect(
      result,
      isA<Ok<AppUser>>().having((ok) => ok.value, 'value', testUser),
    );
    expect(analytics.events, [const AnalyticsEvent.signedIn()]);
  });

  test('AUTH-8: a failed sign-in sends no event', () async {
    const failure = Failure.auth(AuthFailureReason.invalidCredentials);
    when(() => repository.signIn(email: email, password: password))
        .thenAnswer((_) async => const Err(failure));

    final result = await useCase((email: email, password: password));

    expect(
      result,
      isA<Err<AppUser>>().having((err) => err.failure, 'failure', failure),
    );
    expect(analytics.events, isEmpty);
  });
}
