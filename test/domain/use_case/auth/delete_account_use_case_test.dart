import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/delete_account_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  late MockAuthRepository repository;
  late MockFavoriteRepository favoriteRepository;
  late FakeAnalyticsService analytics;
  late DeleteAccountUseCase useCase;

  setUp(() {
    repository = signedInAuthRepository();
    favoriteRepository = MockFavoriteRepository();
    when(() => favoriteRepository.clearForUser(testUser.id))
        .thenAnswer((_) async => const Ok(null));
    analytics = FakeAnalyticsService();
    useCase = DeleteAccountUseCase(repository, favoriteRepository, analytics);
  });

  test('PRF-5, PRF-6: re-authenticates first, then deletes the account and favorites', () async {
    when(() => repository.reauthenticate(password: 'secret1'))
        .thenAnswer((_) async => const Ok(null));
    when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));

    final result = await useCase((password: 'secret1'));

    expect(result, isA<Ok<void>>());
    verifyInOrder([
      () => repository.reauthenticate(password: 'secret1'),
      repository.authStateChanges,
      repository.deleteAccount,
      () => favoriteRepository.clearForUser(testUser.id),
    ]);
  });

  test(
    'PRF-6: a failure to clear the favorites does not fail the deletion',
    () async {
      when(() => repository.reauthenticate(password: 'secret1'))
          .thenAnswer((_) async => const Ok(null));
      when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));
      when(() => favoriteRepository.clearForUser(testUser.id))
          .thenAnswer((_) async => const Err(Failure.cache()));

      final result = await useCase((password: 'secret1'));

      expect(result, isA<Ok<void>>());
      verify(() => favoriteRepository.clearForUser(testUser.id)).called(1);
    },
  );

  test('PRF-7: a wrong password stops before deletion', () async {
    const failure = Failure.auth(AuthFailureReason.invalidCredentials);
    when(() => repository.reauthenticate(password: 'wrong11'))
        .thenAnswer((_) async => const Err(failure));

    final result = await useCase((password: 'wrong11'));

    expect(
      result,
      isA<Err<void>>().having((e) => e.failure, 'failure', failure),
    );
    verifyNever(repository.deleteAccount);
    verifyNever(() => favoriteRepository.clearForUser(any()));
  });

  test(
    'PRF-7: returns the failure of the deletion and keeps the favorites',
    () async {
      const failure = Failure.network();
      when(() => repository.reauthenticate(password: 'secret1'))
          .thenAnswer((_) async => const Ok(null));
      when(repository.deleteAccount)
          .thenAnswer((_) async => const Err(failure));

      final result = await useCase((password: 'secret1'));

      expect(
        result,
        isA<Err<void>>().having((e) => e.failure, 'failure', failure),
      );
      verifyNever(() => favoriteRepository.clearForUser(any()));
    },
  );

  test('PRF-8: a deletion logs account_deleted', () async {
    when(() => repository.reauthenticate(password: 'secret1'))
        .thenAnswer((_) async => const Ok(null));
    when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));

    await useCase((password: 'secret1'));

    expect(analytics.events, [const AnalyticsEvent.accountDeleted()]);
  });

  test('PRF-8: a failed deletion logs nothing', () async {
    when(() => repository.reauthenticate(password: 'secret1'))
        .thenAnswer((_) async => const Ok(null));
    when(repository.deleteAccount)
        .thenAnswer((_) async => const Err(Failure.network()));

    await useCase((password: 'secret1'));

    expect(analytics.events, isEmpty);
  });
}
