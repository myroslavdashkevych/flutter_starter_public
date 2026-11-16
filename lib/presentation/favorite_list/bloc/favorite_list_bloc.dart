import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/user_favorites.dart';
import 'package:flutter_starter/domain/use_case/favorite/toggle_favorite_use_case.dart';
import 'package:flutter_starter/domain/use_case/favorite/watch_favorites_use_case.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_event.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class FavoriteListBloc extends Bloc<FavoriteListEvent, FavoriteListState> {
  FavoriteListBloc(this._watchFavorites, this._toggleFavorite)
    : super(const FavoriteListState()) {
    on<FavoriteListStarted>(_onStarted, transformer: restartable());
    on<FavoriteListRemoveRequested>(
      _onRemoveRequested,
      transformer: droppable(),
    );
    add(const FavoriteListStarted());
  }

  final WatchFavoritesUseCase _watchFavorites;
  final ToggleFavoriteUseCase _toggleFavorite;

  Future<void> _onStarted(
    FavoriteListStarted event,
    Emitter<FavoriteListState> emit,
  ) => emit.onEach(
    _watchFavorites(()),
    onData: (favorites) => emit(switch (favorites) {
      GuestFavorites() => state.copyWith(
        authStatus: FavoriteListAuthStatus.guest,
        characters: const [],
      ),
      SignedInFavorites(:final characters) => state.copyWith(
        authStatus: FavoriteListAuthStatus.signedIn,
        characters: characters,
      ),
    }),
  );

  Future<void> _onRemoveRequested(
    FavoriteListRemoveRequested event,
    Emitter<FavoriteListState> emit,
  ) async {
    final character = state.characters
        ?.where((character) => character.id == event.id)
        .firstOrNull;
    if (character == null) return;
    emit(state.copyWith(removeFailure: null));
    final result = await _toggleFavorite((character: character));
    if (result case Err(:final failure)) {
      emit(state.copyWith(removeFailure: failure));
    }
  }
}
