import 'package:flutter_starter/domain/_shared/base/use_case/stream_use_case.dart';
import 'package:flutter_starter/domain/entity/user_favorites.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/repository/favorite_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

/// Follows the current user and their favorites. A user change replaces the
/// previous user's favorites at once: they are unknown until the new user's
/// favorites are read (FAV-12, FAV-16).
@injectable
class WatchFavoritesUseCase implements StreamUseCase<UserFavorites, ()> {
  WatchFavoritesUseCase(this._authRepository, this._favoriteRepository);

  final AuthRepository _authRepository;
  final FavoriteRepository _favoriteRepository;

  @override
  Stream<UserFavorites> call(() params) => _authRepository
      .authStateChanges()
      .map((user) => user?.id)
      .distinct()
      .switchMap(
        (uid) => uid == null
            ? Stream.value(const UserFavorites.guest())
            : _favoriteRepository
                  .watchAll(uid)
                  .map(
                    (characters) =>
                        UserFavorites.signedIn(characters: characters),
                  )
                  .startWith(const UserFavorites.signedIn()),
      );
}
