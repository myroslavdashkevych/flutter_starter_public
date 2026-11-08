import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/favorites/usecases/toggle_favorite_use_case.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/fake_favorites_repository.dart';
import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late StreamController<AppUser?> users;
  late FakeFavoritesRepository favorites;

  FavoritesCubit build() => FavoritesCubit(
    authRepository,
    favorites,
    ToggleFavoriteUseCase(favorites, FakeAnalyticsService()),
  );

  setUp(() {
    users = StreamController<AppUser?>.broadcast();
    authRepository = MockAuthRepository();
    when(authRepository.authStateChanges).thenAnswer((_) => users.stream);
    favorites = FakeFavoritesRepository([testItem(2), testItem(1)]);
  });

  tearDown(() => users.close());

  test('starts with an unknown auth state and no items', () async {
    final cubit = build();
    addTearDown(cubit.close);

    expect(cubit.state.authStatus, FavoritesAuthStatus.unknown);
    expect(cubit.state.items, isNull);
  });

  blocTest<FavoritesCubit, FavoritesState>(
    'FAV-5: a user sees the items in the repository order',
    build: build,
    act: (_) => users.add(testUser),
    wait: Duration.zero,
    verify: (cubit) {
      expect(cubit.state.authStatus, FavoritesAuthStatus.signedIn);
      expect(cubit.state.items, [testItem(2), testItem(1)]);
    },
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'FAV-6: a guest gets the guest state',
    build: build,
    act: (_) => users.add(null),
    wait: Duration.zero,
    verify: (cubit) {
      expect(cubit.state.authStatus, FavoritesAuthStatus.guest);
    },
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'FAV-3: removing an item elsewhere updates the list',
    build: build,
    act: (_) async {
      await Future<void>.delayed(Duration.zero);
      await favorites.toggle(testItem(2));
    },
    wait: Duration.zero,
    verify: (cubit) => expect(cubit.state.items, [testItem(1)]),
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'FAV-15: remove takes the item out by its id',
    build: build,
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      await cubit.remove(1);
    },
    wait: Duration.zero,
    verify: (cubit) => expect(cubit.state.items, [testItem(2)]),
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'FAV-4: a failed remove keeps the item and reports the failure',
    build: () {
      favorites.toggleFailure = const Failure.cache();
      return build();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      await cubit.remove(1);
    },
    verify: (cubit) {
      expect(cubit.state.items, [testItem(2), testItem(1)]);
      expect(cubit.state.removeFailure, const Failure.cache());
    },
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'removing an id that is not a favorite does nothing',
    build: build,
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      await cubit.remove(99);
    },
    verify: (cubit) {
      expect(cubit.state.items, [testItem(2), testItem(1)]);
      expect(cubit.state.removeFailure, isNull);
    },
  );
}
