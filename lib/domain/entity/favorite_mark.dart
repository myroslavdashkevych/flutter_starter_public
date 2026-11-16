import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_mark.freezed.dart';

/// Whether one character is a favorite of whoever uses the app now.
@freezed
sealed class FavoriteMark with _$FavoriteMark {
  /// No user is signed in, so the character has no mark.
  const factory FavoriteMark.guest() = GuestFavoriteMark;

  /// [isFavorite] is false until the user's favorites are read.
  const factory FavoriteMark.signedIn({required bool isFavorite}) =
      SignedInFavoriteMark;
}
