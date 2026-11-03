import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';

/// Favorites of the current user. A guest has none.
abstract class FavoritesRepository {
  /// Emits the current favorites, newest first, on listen and on every change.
  Stream<List<Item>> watchAll();

  /// Emits whether the item is a favorite on listen and on every change.
  Stream<bool> watchIsFavorite(int id);

  /// Adds or removes [item] and returns whether it is a favorite now.
  Future<Result<bool>> toggle(Item item);

  /// Removes everything stored for the user [uid], signed in or not.
  Future<Result<void>> clearForUser(String uid);
}
