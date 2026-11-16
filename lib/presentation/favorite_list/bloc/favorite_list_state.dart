import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_list_state.freezed.dart';

enum FavoriteListAuthStatus { unknown, guest, signedIn }

@freezed
abstract class FavoriteListState with _$FavoriteListState {
  const factory FavoriteListState({
    @Default(FavoriteListAuthStatus.unknown) FavoriteListAuthStatus authStatus,

    /// Null until the repository has read the favorites.
    List<Character>? characters,
    Failure? removeFailure,
  }) = _FavoriteListState;

  const FavoriteListState._();

  bool contains(int id) =>
      characters?.any((character) => character.id == id) ?? false;
}
