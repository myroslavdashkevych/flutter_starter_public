import 'package:flutter_starter/domain/_shared/base/use_case/stream_use_case.dart';
import 'package:flutter_starter/domain/entity/favorite_mark.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/repository/favorite_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

/// Follows the current user and whether a character is their favorite. A user
/// change never shows the previous user's mark (FAV-16).
@injectable
class WatchFavoriteMarkUseCase
    implements StreamUseCase<FavoriteMark, ({int characterId})> {
  WatchFavoriteMarkUseCase(this._authRepository, this._favoriteRepository);

  final AuthRepository _authRepository;
  final FavoriteRepository _favoriteRepository;

  @override
  Stream<FavoriteMark> call(({int characterId}) params) => _authRepository
      .authStateChanges()
      .map((user) => user?.id)
      .distinct()
      .switchMap(
        (uid) => uid == null
            ? Stream.value(const FavoriteMark.guest())
            : _favoriteRepository
                  .watchIsFavorite(uid, params.characterId)
                  .map(
                    (isFavorite) =>
                        FavoriteMark.signedIn(isFavorite: isFavorite),
                  )
                  .startWith(const FavoriteMark.signedIn(isFavorite: false)),
      );
}
