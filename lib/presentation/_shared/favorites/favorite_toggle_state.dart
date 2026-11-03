import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_toggle_state.freezed.dart';

@freezed
abstract class FavoriteToggleState with _$FavoriteToggleState {
  const factory FavoriteToggleState({
    @Default(false) bool isSignedIn,
    @Default(false) bool isFavorite,
    Failure? failure,
  }) = _FavoriteToggleState;
}
