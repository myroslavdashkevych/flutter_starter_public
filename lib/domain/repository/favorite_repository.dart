import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';

/// Favorites of the user [uid]. The repository does not know who is signed in:
/// the favorites use cases pass the current user.
abstract interface class FavoriteRepository {
  /// Emits the user's favorites, newest first, once read and on every change.
  Stream<List<Character>> watchAll(String uid);

  /// Emits whether the character is a favorite of the user, once read and on every
  /// change.
  Stream<bool> watchIsFavorite(String uid, int id);

  /// Adds or removes [character] for the user and returns whether it is a favorite
  /// now.
  Future<Result<bool>> toggle(String uid, Character character);

  /// Removes everything stored for the user, signed in or not.
  Future<Result<void>> clearForUser(String uid);
}
