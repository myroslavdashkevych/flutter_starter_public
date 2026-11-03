import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/items/usecases/get_items_page_use_case.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_event.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_state.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

@injectable
class ItemsListBloc extends Bloc<ItemsListEvent, ItemsListState> {
  ItemsListBloc(this._getItemsPage, this._analytics)
    : super(const ItemsListState()) {
    on<ItemsListLoadRequested>(
      (event, emit) => _loadFirstPage(state.query, emit),
    );
    on<ItemsListSearchChanged>(
      _onSearchChanged,
      transformer: (events, mapper) =>
          events.debounce(searchDebounce).switchMap(mapper),
    );
    on<ItemsListRefreshRequested>(_onRefreshRequested);
    on<ItemsListNextPageRequested>(_onNextPageRequested);
  }

  static const searchDebounce = Duration(milliseconds: 400);

  final GetItemsPageUseCase _getItemsPage;
  final AnalyticsService _analytics;

  Future<void> _onSearchChanged(
    ItemsListSearchChanged event,
    Emitter<ItemsListState> emit,
  ) async {
    if (event.query == state.query) return;
    if (event.query.isNotEmpty) {
      unawaited(
        _analytics.logEvent(
          AnalyticsEvents.search,
          parameters: {AnalyticsParams.searchTerm: event.query},
        ),
      );
    }
    await _loadFirstPage(event.query, emit);
  }

  Future<void> _loadFirstPage(
    String query,
    Emitter<ItemsListState> emit,
  ) async {
    final generation = state.generation + 1;
    emit(ItemsListState(query: query, generation: generation));

    final result = await _getItemsPage(page: 1, query: query);
    if (generation != state.generation) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        status: ItemsListStatus.loaded,
        items: value.items,
        page: value.page,
        hasMore: value.hasMore,
      ),
      Err(:final failure) => state.copyWith(
        status: ItemsListStatus.failure,
        failure: failure,
      ),
    });
  }

  Future<void> _onRefreshRequested(
    ItemsListRefreshRequested event,
    Emitter<ItemsListState> emit,
  ) async {
    if (state.status != ItemsListStatus.loaded || state.isRefreshing) return;

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

    final result = await _getItemsPage(
      page: 1,
      query: state.query,
      forceRefresh: true,
    );
    if (generation != state.generation) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        isRefreshing: false,
        items: value.items,
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
    ItemsListNextPageRequested event,
    Emitter<ItemsListState> emit,
  ) async {
    if (state.status != ItemsListStatus.loaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.isRefreshing) {
      return;
    }

    final generation = state.generation;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailure: null));

    final result = await _getItemsPage(
      page: state.page + 1,
      query: state.query,
    );
    if (generation != state.generation) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...value.items],
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
