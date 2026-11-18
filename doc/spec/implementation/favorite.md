# Implementation: favorite

**Code:** `domain/entity/user_favorites.dart`, `domain/entity/favorite_mark.dart`,
`domain/repository/favorite_repository.dart`, `domain/use_case/favorite`, `data/favorite`, `presentation/favorite_list`; the toggle lives in
`presentation/_shared/component/favorite_toggle`. Behavior:
[behavior/favorite.md](../behavior/favorite.md).

Changes reach every screen through streams.

## Domain

- Uses the `Character` entity.
- `FavoriteRepository` does not know who is signed in; every method takes the user id
  ([architecture.md](../architecture.md), Inside domain):
  - `Stream<List<Character>> watchAll(String uid)`: newest first, once read and on every change
  - `Stream<bool> watchIsFavorite(String uid, int id)`
  - `Future<Result<bool>> toggle(String uid, Character character)`: returns the new state
  - `Future<Result<void>> clearForUser(String uid)`: deletes everything stored for that user,
    signed in or not
- Entities: `UserFavorites` (`guest`, or `signedIn` with `characters` that are null until read)
  and `FavoriteMark` (`guest`, or `signedIn` with `isFavorite`, false until read).
- The favorites use cases supply the current user from `AuthRepository`:
  - `WatchFavoritesUseCase`: follows `authStateChanges()`, distinct by user id, and switches
    (`switchMap`) to `UserFavorites.guest()` or to that user's `watchAll`, starting with
    `signedIn(characters: null)`, so a user change hides the previous favorites at once (FAV-12,
    FAV-16).
  - `WatchFavoriteMarkUseCase`: the same with `watchIsFavorite`, starting with
    `signedIn(isFavorite: false)`.
  - `ToggleFavoriteUseCase`: reads the current user (`authStateChanges().first`); a guest
    gets `UnexpectedFailure`, since a guest sees no toggle (FAV-2). Otherwise it toggles through the repository and, when the
    toggle succeeds, sends `add_to_wishlist` or `remove_from_wishlist` with `item_id`
    (FAV-11).
  - `DeleteAccountUseCase` ([profile.md](profile.md)) calls `clearForUser` with the deleted
    user's id.

## Data

- `FavoriteHiveDataSource` (`data_source/favorite_hive_data_source.dart`): hive_ce
  `LazyBox` per user, `favorite_<uid in hex>` (the user id in hex, as for every
  case-sensitive box name part).
- Key: the character id. Envelope, `FavoriteRecordDto`:
  `{ "schemaVersion": 1, "addedAt": <iso8601 UTC>, "data": <dto.toJson()> }`.
- `FavoriteCharacterDto` is a snapshot of `Character`. This is user data, not a cache
  ([architecture.md](../architecture.md), Cache or user data), with every rule of user data
  there; when it is deleted: FAV-7.
- Toggling a character whose record is unreadable overwrites that record.
- The repository keeps the records of each user that something uses in memory. A user's box
  is opened on first use (a listener or an operation) and closed, with the memory state,
  when that user has no listener and no pending operation. Storage operations of all users
  run one at a time.
- If the box cannot be opened, the failure is logged and the list is empty; the next `toggle`
  or a new listener of that user tries to read it again, and a `toggle` returns
  `CacheFailure` if that fails too.

## Presentation

- `FavoriteToggleBloc` and `FavoriteToggle` in the component
  `presentation/_shared/component/favorite_toggle`, shown on each
  character list tile and in the character details app bar. Pages receive the toggle through a builder
  from the route builder ([architecture.md](../architecture.md), Routing), which adds
  `FavoriteToggleStarted(characterId)`. A tap is `droppable`: another tap while a toggle runs is
  ignored (FAV-17). It follows `WatchFavoriteMarkUseCase`.
- `FavoriteListBloc` follows `WatchFavoritesUseCase`, started by its constructor. Both Blocs
  toggle through `ToggleFavoriteUseCase`.
- `/profile/favorite-list/:id` is the `character_detail` page and loads through
  `GetCharacterDetailUseCase`, not from the snapshot. The **Remove from favorites** action is passed as `notFoundActionBuilder`.
