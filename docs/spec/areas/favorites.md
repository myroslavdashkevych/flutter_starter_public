# Area: favorites

**Areas:** `domain/favorites`, `data/favorites`, `presentation/favorites`; the toggle lives in
`presentation/_shared/bloc/favorite` and `presentation/_shared/widgets/button`. Behavior:
[features/favorites.md](../features/favorites.md).

Changes reach every screen through streams.

## Domain

- Uses the `Item` entity from `domain/items`.
- `FavoritesRepository`:
  - `Stream<List<Item>> watchAll()`: newest first; empty for a guest
  - `Stream<bool> watchIsFavorite(int id)`
  - `Future<Result<bool>> toggle(Item item)`: returns the new state
  - `Future<Result<void>> clearForUser(String uid)`: deletes everything stored for that user,
    signed in or not
- `domain/favorites/usecases/toggle_favorite_use_case.dart`: toggles through the repository
  and, when the toggle succeeds, sends `add_to_wishlist` or `remove_from_wishlist` with
  `item_id` (FAV-11).

## Data

- hive_ce `LazyBox` per user, `favorites_<uid in hex>` (the user id in hex, as for every
  case-sensitive box name part).
- Key: the item id. Envelope:
  `{ "schemaVersion": 1, "addedAt": <iso8601>, "data": <dto.toJson()> }`.
- `FavoriteItemDto` is a snapshot of `Item`. This is user data, not a cache
  ([architecture.md](../architecture.md), Cache or user data), with every rule of user data
  there.
  It is deleted when the user removes a favorite or deletes the account.
- Toggling an item whose record is unreadable overwrites that record.
- The repository follows `AuthRepository.authStateChanges()`. On a user change it hides the
  previous favorites at once, closes the old box and opens the new one; after sign-out the
  state is empty. Storage operations run one at a time.
- If the box cannot be opened, the failure is logged and the list is empty; the next `toggle`
  tries to read it again and returns `CacheFailure` if that fails too.

## Presentation

- `FavoriteToggleCubit` in `presentation/_shared/bloc/favorite` and `FavoriteToggle` in
  `presentation/_shared/widgets/button`, shown on each
  item list tile and in the item details app bar. Pages receive the toggle through a builder
  from the route builder ([architecture.md](../architecture.md), Routing).
- `FavoritesCubit` follows the auth state and `watchAll()`.
- `/profile/favorites/:id` is the `item_details` page and loads through `ItemsRepository`, not
  from the snapshot. The **Remove from favorites** action is passed as `notFoundActionBuilder`.
