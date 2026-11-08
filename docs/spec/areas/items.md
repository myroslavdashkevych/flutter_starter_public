# Area: items

**Areas:** `domain/items`, `data/items`, `presentation/items_list`, `presentation/item_details`.
Behavior: [features/items.md](../features/items.md).

Both features use the same `ItemsRepository` from `domain/items`: this is the reference
example of one domain area serving several features.

## Source

Rick and Morty API, characters endpoint, via `publicDio` (no auth header).

- List: `GET /character?page={page}&name={query}`; 20 per page; `info.next == null` means the
  last page.
- Details: `GET /character/{id}`.
- An empty search result is returned by the API as HTTP 404 with an error body
  (`{"error":"There is nothing here"}`, verified). A page past the last one answers the same
  way. `data/items` maps a list 404 to an empty `Paginated` result, **not** to a failure, and
  does not cache it. A 404 for details stays `NotFoundFailure`, even with a stale cache,
  because the item no longer exists.

## Domain

- `Item` entity: `id`, `name`, `imageUrl`, `status` (`ItemStatus`: alive, dead, unknown),
  `species`, `gender`, `originName`, `locationName`, `episodeCount`.
- `ItemsRepository`:
  - `Future<Result<Paginated<Item>>> getPage({required int page, String? query, bool forceRefresh = false})`
  - `Future<Result<Item>> getById(int id)`
- Use cases (reference example of use cases, [architecture.md](../architecture.md), Data flow):
  - `domain/items/usecases/get_items_page_use_case.dart`
  - `domain/items/usecases/get_item_details_use_case.dart`

## Data

- `ItemsApi` (retrofit), `CharacterDto`, `PageInfoDto`, `CharactersPageDto` (the list
  response: `info` and `results`), mapper `toEntity()`.
- Cache in hive_ce `LazyBox` (`items_cache`); this is the starter's example of a cache
  ([architecture.md](../architecture.md), Local storage):
  - key: `list:page={page}:q={query}` and `item:{id}`;
  - envelope: `{ "schemaVersion": 1, "fetchedAt": <iso8601>, "data": <dto.toJson()> }`;
  - TTL from `ITEMS_CACHE_TTL_MINUTES` (default 30);
  - `maxAge`: 90 days;
  - writing a page also writes `item:{id}` for each of its items, so details open offline for
    everything in a cached list;
  - the box is opened on first use; parallel first calls share one opening `Future`.
- A record that is unreadable or has another `schemaVersion` is refetched, and eviction
  deletes old records, as for every cache (Local storage, Cache or user data). Until eviction
  a record can still be shown offline.
- Strategy:
  1. Fresh cache hit and not `forceRefresh` → return cache.
  2. Otherwise request the network; on success write to cache and return.
  3. On a network or server (5xx) failure → return stale cache if present, else the failure.
     So a refresh without a connection shows the cached data, not an error.

## Presentation

- `items_list`: a `Bloc`, because search uses a debounce and a `restartable` transformer. Older
  results are dropped by checking a generation counter in the state (ITM-5).
- The image widget with its retries is `presentation/_shared/widgets/item/item_image.dart`.
- The API host limits bursts of requests (HTTP 429, `retry-after: 10`), which fast scrolling
  reaches with an empty image cache.
