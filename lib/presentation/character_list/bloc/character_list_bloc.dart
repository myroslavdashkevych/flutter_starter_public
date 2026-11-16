import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_page_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_search_use_case.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_event.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_state.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

@injectable
class CharacterListBloc extends Bloc<CharacterListEvent, CharacterListState> {
  CharacterListBloc(this._getCharacterPage, this._trackSearch)
    : super(const CharacterListState()) {
    // Load, search and refresh replace the first page; the generation counter
    // in the state drops a result that is no longer current (CHR-5).
    on<CharacterListLoadRequested>(
      (event, emit) => _loadFirstPage(state.query, emit),
      transformer: restartable(),
    );
    on<CharacterListSearchChanged>(
      _onSearchChanged,
      transformer: (events, mapper) =>
          events.debounce(searchDebounce).switchMap(mapper),
    );
    on<CharacterListRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<CharacterListNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
  }

  final GetCharacterPageUseCase _getCharacterPage;
  final TrackSearchUseCase _trackSearch;

  static const searchDebounce = Duration(milliseconds: 400);

  Future<void> _onSearchChanged(
    CharacterListSearchChanged event,
    Emitter<CharacterListState> emit,
  ) async {
    if (event.query == state.query) return;
    if (event.query.isNotEmpty) {
      unawaited(_trackSearch((term: event.query)));
    }
    await _loadFirstPage(event.query, emit);
  }

  Future<void> _loadFirstPage(
    String query,
    Emitter<CharacterListState> emit,
  ) async {
    final generation = state.generation + 1;
    emit(CharacterListState(query: query, generation: generation));

    final result = await _getCharacterPage((
      page: 1,
      query: query,
      forceRefresh: false,
    ));
    if (generation != state.generation) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        status: CharacterListStatus.loaded,
        characters: value.items,
        page: value.page,
        hasMore: value.hasMore,
      ),
      Err(:final failure) => state.copyWith(
        status: CharacterListStatus.failure,
        failure: failure,
      ),
    });
  }

  Future<void> _onRefreshRequested(
    CharacterListRefreshRequested event,
    Emitter<CharacterListState> emit,
  ) async {
    if (state.status != CharacterListStatus.loaded || state.isRefreshing) {
      return;
    }

    final generation = state.generation + 1;
    emit(
      state.copyWith(
        generation: generation,
        isRefreshing: true,
        isLoadingMore: false,
        loadMoreFailure: null,
        refreshFailure: null,
      ),
    );

    final result = await _getCharacterPage((
      page: 1,
      query: state.query,
      forceRefresh: true,
    ));
    if (generation != state.generation) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        isRefreshing: false,
        characters: value.items,
        page: value.page,
        hasMore: value.hasMore,
      ),
      Err(:final failure) => state.copyWith(
        isRefreshing: false,
        refreshFailure: failure,
      ),
    });
  }

  Future<void> _onNextPageRequested(
    CharacterListNextPageRequested event,
    Emitter<CharacterListState> emit,
  ) async {
    if (state.status != CharacterListStatus.loaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.isRefreshing) {
      return;
    }

    final generation = state.generation;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailure: null));

    final result = await _getCharacterPage((
      page: state.page + 1,
      query: state.query,
      forceRefresh: false,
    ));
    if (generation != state.generation) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        isLoadingMore: false,
        characters: [...state.characters, ...value.items],
        page: value.page,
        hasMore: value.hasMore,
      ),
      Err(:final failure) => state.copyWith(
        isLoadingMore: false,
        loadMoreFailure: failure,
      ),
    });
  }
}
