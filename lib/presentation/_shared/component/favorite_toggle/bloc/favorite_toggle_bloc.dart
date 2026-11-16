import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/favorite_mark.dart';
import 'package:flutter_starter/domain/use_case/favorite/toggle_favorite_use_case.dart';
import 'package:flutter_starter/domain/use_case/favorite/watch_favorite_mark_use_case.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_event.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class FavoriteToggleBloc
    extends Bloc<FavoriteToggleEvent, FavoriteToggleState> {
  FavoriteToggleBloc(this._watchFavoriteMark, this._toggleFavorite)
    : super(const FavoriteToggleState()) {
    on<FavoriteToggleStarted>(_onStarted, transformer: restartable());
    // A tap while a toggle runs is ignored (FAV-17).
    on<FavoriteToggleTapped>(_onTapped, transformer: droppable());
  }

  final WatchFavoriteMarkUseCase _watchFavoriteMark;
  final ToggleFavoriteUseCase _toggleFavorite;

  Future<void> _onStarted(
    FavoriteToggleStarted event,
    Emitter<FavoriteToggleState> emit,
  ) => emit.onEach(
    _watchFavoriteMark((characterId: event.characterId)),
    onData: (mark) => emit(switch (mark) {
      GuestFavoriteMark() => state.copyWith(
        isSignedIn: false,
        isFavorite: false,
      ),
      SignedInFavoriteMark(:final isFavorite) => state.copyWith(
        isSignedIn: true,
        isFavorite: isFavorite,
      ),
    }),
  );

  Future<void> _onTapped(
    FavoriteToggleTapped event,
    Emitter<FavoriteToggleState> emit,
  ) async {
    emit(state.copyWith(failure: null));
    final result = await _toggleFavorite((character: event.character));
    if (result case Err(:final failure)) {
      emit(state.copyWith(failure: failure));
    }
  }
}
