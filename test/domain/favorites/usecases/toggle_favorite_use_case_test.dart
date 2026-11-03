import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/favorites/usecases/toggle_favorite_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockFavoritesRepository repository;
  late FakeAnalyticsService analytics;
  late ToggleFavoriteUseCase useCase;

  setUp(() {
    repository = MockFavoritesRepository();
    analytics = FakeAnalyticsService();
    useCase = ToggleFavoriteUseCase(repository, analytics);
  });

  test('returns the new state from the repository', () async {
    when(() => repository.toggle(testItem(1)))
        .thenAnswer((_) async => const Ok(true));

    final result = await useCase(testItem(1));

    expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue));
  });

  test('returns the failure from the repository', () async {
    when(() => repository.toggle(testItem(1)))
        .thenAnswer((_) async => const Err(Failure.cache()));

    final result = await useCase(testItem(1));

    expect(
      result,
      isA<Err<bool>>().having((e) => e.failure, 'failure', isA<CacheFailure>()),
    );
  });

  test('adding logs add_to_wishlist', () async {
    when(() => repository.toggle(testItem(1)))
        .thenAnswer((_) async => const Ok(true));

    await useCase(testItem(1));

    expect(analytics.events, [
      [
        AnalyticsEvents.addToWishlist,
        {AnalyticsParams.itemId: '1'},
      ],
    ]);
  });

  test('removing logs remove_from_wishlist', () async {
    when(() => repository.toggle(testItem(1)))
        .thenAnswer((_) async => const Ok(false));

    await useCase(testItem(1));

    expect(analytics.events, [
      [
        AnalyticsEvents.removeFromWishlist,
        {AnalyticsParams.itemId: '1'},
      ],
    ]);
  });

  test('a failure logs nothing', () async {
    when(() => repository.toggle(testItem(1)))
        .thenAnswer((_) async => const Err(Failure.cache()));

    await useCase(testItem(1));

    expect(analytics.events, isEmpty);
  });
}
