import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/favorites/usecases/toggle_favorite_use_case.dart';
import 'package:flutter_starter/presentation/_shared/bloc/favorite/favorite_toggle_cubit.dart';
import 'package:flutter_starter/presentation/_shared/bloc/favorite/favorite_toggle_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_fixtures.dart';
import '../../../../helpers/fake_analytics_service.dart';
import '../../../../helpers/fake_favorites_repository.dart';
import '../../../../helpers/items_fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late FakeFavoritesRepository favorites;

  FavoriteToggleCubit build() => FavoriteToggleCubit(
    authRepository,
    favorites,
    ToggleFavoriteUseCase(favorites, FakeAnalyticsService()),
  );

  setUp(() {
    authRepository = signedInAuthRepository();
    favorites = FakeFavoritesRepository();
  });

  blocTest<FavoriteToggleCubit, FavoriteToggleState>(
    'FAV-2: a guest is not signed in',
    setUp: () {
      when(authRepository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
    },
    build: build,
    act: (cubit) => cubit.watch(1),
    wait: Duration.zero,
    verify: (cubit) {
      expect(cubit.state.isSignedIn, isFalse);
      expect(cubit.state.isFavorite, isFalse);
    },
  );

  blocTest<FavoriteToggleCubit, FavoriteToggleState>(
    'FAV-1: a user sees the current state of the item',
    setUp: () => favorites = FakeFavoritesRepository([testItem(1)]),
    build: build,
    act: (cubit) => cubit.watch(1),
    wait: Duration.zero,
    verify: (cubit) {
      expect(cubit.state.isSignedIn, isTrue);
      expect(cubit.state.isFavorite, isTrue);
    },
  );

  blocTest<FavoriteToggleCubit, FavoriteToggleState>(
    'FAV-3: follows a change made on another screen',
    build: build,
    act: (cubit) async {
      cubit.watch(1);
      await Future<void>.delayed(Duration.zero);
      await favorites.toggle(testItem(1));
    },
    wait: Duration.zero,
    verify: (cubit) => expect(cubit.state.isFavorite, isTrue),
  );

  blocTest<FavoriteToggleCubit, FavoriteToggleState>(
    'FAV-1: toggle flips the state',
    build: build,
    act: (cubit) async {
      cubit.watch(1);
      await Future<void>.delayed(Duration.zero);
      await cubit.toggle(testItem(1));
    },
    wait: Duration.zero,
    verify: (cubit) {
      expect(cubit.state.isFavorite, isTrue);
      expect(cubit.state.failure, isNull);
    },
  );

  blocTest<FavoriteToggleCubit, FavoriteToggleState>(
    'FAV-4: a failed toggle reports the failure and keeps the state',
    setUp: () {
      favorites.toggleFailure = const Failure.cache();
    },
    build: build,
    act: (cubit) async {
      cubit.watch(1);
      await Future<void>.delayed(Duration.zero);
      await cubit.toggle(testItem(1));
    },
    verify: (cubit) {
      expect(cubit.state.isFavorite, isFalse);
      expect(cubit.state.failure, const Failure.cache());
    },
  );
}
