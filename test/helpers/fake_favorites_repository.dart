import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/favorites/repositories/favorites_repository.dart';
import 'package:flutter_starter/domain/favorites/usecases/toggle_favorite_use_case.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/_shared/bloc/favorite/favorite_toggle_cubit.dart';
import 'package:flutter_starter/presentation/_shared/widgets/button/favorite_toggle.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:get_it/get_it.dart';

import 'fake_analytics_service.dart';

/// In-memory favorites of one user, newest first.
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository([List<Item> items = const []])
    : items = List.of(items);

  final List<Item> items;
  final _changes = StreamController<void>.broadcast();

  /// When set, [toggle] fails with it.
  Failure? toggleFailure;

  @override
  Stream<List<Item>> watchAll() => Stream.multi((listener) {
    listener.add(List.of(items));
    final subscription = _changes.stream.listen(
      (_) => listener.add(List.of(items)),
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Stream<bool> watchIsFavorite(int id) =>
      watchAll().map((all) => all.any((item) => item.id == id)).distinct();

  @override
  Future<Result<bool>> toggle(Item item) async {
    final failure = toggleFailure;
    if (failure != null) return Err(failure);
    final isFavorite = items.any((other) => other.id == item.id);
    if (isFavorite) {
      items.removeWhere((other) => other.id == item.id);
    } else {
      items.insert(0, item);
    }
    _changes.add(null);
    return Ok(!isFavorite);
  }

  @override
  Future<Result<void>> clearForUser(String uid) async {
    items.clear();
    _changes.add(null);
    return const Ok(null);
  }
}

Widget Function(Item item) favoriteToggleBuilder(
  AuthRepository authRepository,
  FavoritesRepository favoritesRepository,
) =>
    (item) => BlocProvider(
      create: (_) => FavoriteToggleCubit(
        authRepository,
        favoritesRepository,
        ToggleFavoriteUseCase(favoritesRepository, FakeAnalyticsService()),
      )..watch(item.id),
      child: FavoriteToggle(item: item),
    );

void registerFavoriteCubits(
  GetIt getIt,
  AuthRepository authRepository,
  FavoritesRepository favoritesRepository,
) {
  final toggleFavorite = ToggleFavoriteUseCase(
    favoritesRepository,
    FakeAnalyticsService(),
  );
  getIt
    ..registerFactory(
      () => FavoriteToggleCubit(
        authRepository,
        favoritesRepository,
        toggleFavorite,
      ),
    )
    ..registerFactory(
      () => FavoritesCubit(authRepository, favoritesRepository, toggleFavorite),
    );
}
