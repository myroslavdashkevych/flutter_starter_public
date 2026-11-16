import 'package:flutter_starter/domain/entity/character.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_favorites.freezed.dart';

/// The favorites of whoever uses the app now.
@freezed
sealed class UserFavorites with _$UserFavorites {
  /// No user is signed in, so there are no favorites.
  const factory UserFavorites.guest() = GuestFavorites;

  /// [characters] is null until the user's favorites are read, newest first after.
  const factory UserFavorites.signedIn({List<Character>? characters}) =
      SignedInFavorites;
}
