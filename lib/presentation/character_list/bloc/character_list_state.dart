import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_list_state.freezed.dart';

enum CharacterListStatus { loading, loaded, failure }

@freezed
abstract class CharacterListState with _$CharacterListState {
  const factory CharacterListState({
    @Default(CharacterListStatus.loading) CharacterListStatus status,
    @Default(<Character>[]) List<Character> characters,
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
  }) = _CharacterListState;
}
