import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorites_state.freezed.dart';

enum FavoritesAuthStatus { unknown, guest, signedIn }

@freezed
abstract class FavoritesState with _$FavoritesState {
  const FavoritesState._();

  const factory FavoritesState({
    @Default(FavoritesAuthStatus.unknown) FavoritesAuthStatus authStatus,

    /// Null until the repository has read the favorites.
    List<Item>? items,
    Failure? removeFailure,
  }) = _FavoritesState;

  bool contains(int id) => items?.any((item) => item.id == id) ?? false;
}
