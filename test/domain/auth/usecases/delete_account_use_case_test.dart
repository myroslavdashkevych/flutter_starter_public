import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/auth/usecases/delete_account_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late MockFavoritesRepository favoritesRepository;
  late FakeAnalyticsService analytics;
  late DeleteAccountUseCase useCase;

  setUp(() {
    repository = signedInAuthRepository();
    favoritesRepository = MockFavoritesRepository();
    when(() => favoritesRepository.clearForUser(testUser.id))
        .thenAnswer((_) async => const Ok(null));
    analytics = FakeAnalyticsService();
    useCase = DeleteAccountUseCase(repository, favoritesRepository, analytics);
  });

  test('PRF-5, PRF-6: re-authenticates first, then deletes the account and favorites', () async {
    when(() => repository.reauthenticate(password: 'secret1'))
        .thenAnswer((_) async => const Ok(null));
    when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));

    final result = await useCase(password: 'secret1');

    expect(result, isA<Ok<void>>());
    verifyInOrder([
      () => repository.reauthenticate(password: 'secret1'),
      repository.authStateChanges,
      repository.deleteAccount,
      () => favoritesRepository.clearForUser(testUser.id),
    ]);
  });

  test(
    'PRF-6: a failure to clear the favorites does not fail the deletion',
    () async {
      when(() => repository.reauthenticate(password: 'secret1'))
          .thenAnswer((_) async => const Ok(null));
      when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));
      when(() => favoritesRepository.clearForUser(testUser.id))
          .thenAnswer((_) async => const Err(Failure.cache()));

      final result = await useCase(password: 'secret1');

      expect(result, isA<Ok<void>>());
      verify(() => favoritesRepository.clearForUser(testUser.id)).called(1);
    },
  );

  test('PRF-7: a wrong password stops before deletion', () async {
    const failure = Failure.auth(AuthFailureReason.invalidCredentials);
    when(() => repository.reauthenticate(password: 'wrong11'))
        .thenAnswer((_) async => const Err(failure));

    final result = await useCase(password: 'wrong11');

    expect(
      result,
      isA<Err<void>>().having((e) => e.failure, 'failure', failure),
    );
    verifyNever(repository.deleteAccount);
    verifyNever(() => favoritesRepository.clearForUser(any()));
  });

  test(
    'PRF-7: returns the failure of the deletion and keeps the favorites',
    () async {
      const failure = Failure.auth(AuthFailureReason.network);
      when(() => repository.reauthenticate(password: 'secret1'))
          .thenAnswer((_) async => const Ok(null));
      when(repository.deleteAccount)
          .thenAnswer((_) async => const Err(failure));

      final result = await useCase(password: 'secret1');

      expect(
        result,
        isA<Err<void>>().having((e) => e.failure, 'failure', failure),
      );
      verifyNever(() => favoritesRepository.clearForUser(any()));
    },
  );

  test('PRF-8: a deletion logs account_deleted', () async {
    when(() => repository.reauthenticate(password: 'secret1'))
        .thenAnswer((_) async => const Ok(null));
    when(repository.deleteAccount).thenAnswer((_) async => const Ok(null));

    await useCase(password: 'secret1');

    expect(analytics.events, [
      [AnalyticsEvents.accountDeleted, null],
    ]);
  });

  test('PRF-8: a failed deletion logs nothing', () async {
    when(() => repository.reauthenticate(password: 'secret1'))
        .thenAnswer((_) async => const Ok(null));
    when(repository.deleteAccount).thenAnswer(
      (_) async => const Err(Failure.auth(AuthFailureReason.network)),
    );

    await useCase(password: 'secret1');

    expect(analytics.events, isEmpty);
  });
}
