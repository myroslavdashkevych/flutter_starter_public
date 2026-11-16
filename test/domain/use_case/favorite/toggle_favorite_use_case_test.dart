import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/favorite/toggle_favorite_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/character_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  late TestAuthState auth;
  late MockFavoriteRepository repository;
  late FakeAnalyticsService analytics;
  late ToggleFavoriteUseCase useCase;

  setUp(() {
    auth = TestAuthState(testUser);
    repository = MockFavoriteRepository();
    analytics = FakeAnalyticsService();
    useCase = ToggleFavoriteUseCase(auth.repository(), repository, analytics);
  });

  tearDown(() => auth.close());

  test('toggles for the current user and returns the new state', () async {
    when(() => repository.toggle(testUser.id, testCharacter(1)))
        .thenAnswer((_) async => const Ok(true));

    final result = await useCase((character: testCharacter(1)));

    expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue));
    verify(() => repository.toggle(testUser.id, testCharacter(1))).called(1);
  });

  test('returns the failure from the repository', () async {
    when(() => repository.toggle(testUser.id, testCharacter(1)))
        .thenAnswer((_) async => const Err(Failure.cache()));

    final result = await useCase((character: testCharacter(1)));

    expect(
      result,
      isA<Err<bool>>().having((e) => e.failure, 'failure', isA<CacheFailure>()),
    );
  });

  test('FAV-2: a guest cannot change favorites', () async {
    auth.user = null;

    final result = await useCase((character: testCharacter(1)));

    expect(
      result,
      isA<Err<bool>>().having(
        (e) => e.failure,
        'failure',
        const Failure.unexpected(),
      ),
    );
    verifyZeroInteractions(repository);
    expect(analytics.events, isEmpty);
  });

  test('FAV-11: adding logs add_to_wishlist', () async {
    when(() => repository.toggle(testUser.id, testCharacter(1)))
        .thenAnswer((_) async => const Ok(true));

    await useCase((character: testCharacter(1)));

    expect(analytics.events, [
      const AnalyticsEvent.favoriteAdded(characterId: 1),
    ]);
  });

  test('FAV-11: removing logs remove_from_wishlist', () async {
    when(() => repository.toggle(testUser.id, testCharacter(1)))
        .thenAnswer((_) async => const Ok(false));

    await useCase((character: testCharacter(1)));

    expect(analytics.events, [
      const AnalyticsEvent.favoriteRemoved(characterId: 1),
    ]);
  });

  test('FAV-11: a failure logs nothing', () async {
    when(() => repository.toggle(testUser.id, testCharacter(1)))
        .thenAnswer((_) async => const Err(Failure.cache()));

    await useCase((character: testCharacter(1)));

    expect(analytics.events, isEmpty);
  });
}
