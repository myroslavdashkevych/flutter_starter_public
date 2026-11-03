import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'items_list_state.freezed.dart';

enum ItemsListStatus { loading, loaded, failure }

@freezed
abstract class ItemsListState with _$ItemsListState {
  const factory ItemsListState({
    @Default(ItemsListStatus.loading) ItemsListStatus status,
    @Default(<Item>[]) List<Item> items,
    @Default('') String query,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isRefreshing,

    /// Grows when the list restarts, so an older request can detect that its
    /// result no longer applies.
    @Default(0) int generation,
    Failure? failure,
    Failure? loadMoreFailure,
    Failure? refreshFailure,
  }) = _ItemsListState;
}
