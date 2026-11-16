import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/repository/favorite_repository.dart';
import 'package:flutter_starter/domain/use_case/favorite/toggle_favorite_use_case.dart';
import 'package:flutter_starter/domain/use_case/favorite/watch_favorite_mark_use_case.dart';
import 'package:flutter_starter/domain/use_case/favorite/watch_favorites_use_case.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_bloc.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_event.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/widget/favorite_toggle.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_bloc.dart';
import 'package:get_it/get_it.dart';

import 'fake_analytics_service.dart';

/// In-memory favorites, newest first, shared by every user id: tests of
/// separate users use the real repository or the use case tests.
class FakeFavoriteRepository implements FavoriteRepository {
  FakeFavoriteRepository([List<Character> characters = const []])
    : characters = List.of(characters);

  final List<Character> characters;
  final _changes = StreamController<void>.broadcast();

  /// When set, [toggle] fails with it.
  Failure? toggleFailure;

  @override
  Stream<List<Character>> watchAll(String uid) => Stream.multi((listener) {
    listener.add(List.of(characters));
    final subscription = _changes.stream.listen(
      (_) => listener.add(List.of(characters)),
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Stream<bool> watchIsFavorite(String uid, int id) =>
      watchAll(uid)
          .map((all) => all.any((character) => character.id == id))
          .distinct();

  @override
  Future<Result<bool>> toggle(String uid, Character character) async {
    final failure = toggleFailure;
    if (failure != null) return Err(failure);
    final isFavorite = characters.any((other) => other.id == character.id);
    if (isFavorite) {
      characters.removeWhere((other) => other.id == character.id);
    } else {
      characters.insert(0, character);
    }
    _changes.add(null);
    return Ok(!isFavorite);
  }

  @override
  Future<Result<void>> clearForUser(String uid) async {
    characters.clear();
    _changes.add(null);
    return const Ok(null);
  }
}

ToggleFavoriteUseCase toggleFavoriteUseCase(
  AuthRepository authRepository,
  FavoriteRepository favoriteRepository,
) => ToggleFavoriteUseCase(
  authRepository,
  favoriteRepository,
  FakeAnalyticsService(),
);

FavoriteToggleBloc favoriteToggleBloc(
  AuthRepository authRepository,
  FavoriteRepository favoriteRepository,
) => FavoriteToggleBloc(
  WatchFavoriteMarkUseCase(authRepository, favoriteRepository),
  toggleFavoriteUseCase(authRepository, favoriteRepository),
);

FavoriteListBloc favoriteListBloc(
  AuthRepository authRepository,
  FavoriteRepository favoriteRepository,
) => FavoriteListBloc(
  WatchFavoritesUseCase(authRepository, favoriteRepository),
  toggleFavoriteUseCase(authRepository, favoriteRepository),
);

Widget Function(Character character) favoriteToggleBuilder(
  AuthRepository authRepository,
  FavoriteRepository favoriteRepository,
) =>
    (character) => BlocProvider(
      create: (_) =>
          favoriteToggleBloc(authRepository, favoriteRepository)
            ..add(FavoriteToggleStarted(character.id)),
      child: FavoriteToggle(character: character),
    );

void registerFavoriteBlocs(
  GetIt getIt,
  AuthRepository authRepository,
  FavoriteRepository favoriteRepository,
) {
  getIt
    ..registerFactory(
      () => favoriteToggleBloc(authRepository, favoriteRepository),
    )
    ..registerFactory(
      () => favoriteListBloc(authRepository, favoriteRepository),
    );
}
