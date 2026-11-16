# Area: character

**Areas:** `domain/entity/character.dart`,
`domain/repository/character_repository.dart`, `domain/use_case/character`, `data/character`,
`presentation/character_list`,
`presentation/character_detail`. Behavior: [behavior/character.md](../behavior/character.md).

Both features use the same `CharacterRepository` through their use cases: this is the reference
example of one business area serving several features.

## Source

Rick and Morty API, characters endpoint, via `publicDio` (no auth header).

- List: `GET /character?page={page}&name={query}`; 20 per page; `info.next == null` means the
  last page.
- Details: `GET /character/{id}`.
- An empty search result is returned by the API as HTTP 404 with an error body
  (`{"error":"There is nothing here"}`, verified). A page past the last one answers the same
  way. `data/character` maps a list 404 to an empty `Paginated` result, **not** to a failure, and
  does not cache it. A 404 for details stays `NotFoundFailure`, even with a stale cache,
  because the character no longer exists.

## Domain

- `Character` entity: `id`, `name`, `imageUrl`, `status` (`CharacterStatus`: alive, dead,
  unknown), `species`, `gender`, `originName`, `locationName`, `episodeCount`.
- `CharacterRepository`:
  - `Future<Result<Paginated<Character>>> getPage({required int page, String? query, bool forceRefresh = false})`
  - `Future<Result<Character>> getById(int id)`
- Use cases ([architecture.md](../architecture.md), Use cases):
  - `GetCharacterPageUseCase` (a blank query means no search), `GetCharacterDetailUseCase`;
  - `TrackSearchUseCase` (CHR-17) and `TrackCharacterOpenedUseCase` (CHR-18), which the Blocs
    call at the moment the requirement names.

## Data

- `CharacterApiDataSource` (retrofit, `data_source/character_api_data_source.dart`),
  `CharacterDto`, `CharacterPlaceDto`, `PageInfoDto`, `CharacterPageDto` (the list response:
  `info` and `results`), mapper `toEntity()` in `mapper/character_mapper.dart`.
- Cache in hive_ce `LazyBox` (`character_cache`, `CharacterHiveDataSource`); this is the
  starter's example of a cache ([architecture.md](../architecture.md), Local storage):
  - key: `list:page={page}:q={query}` and `character:{id}`;
  - envelope, `CachedRecordDto<T>`:
    `{ "schemaVersion": 1, "fetchedAt": <iso8601>, "data": <dto.toJson()> }`;
  - TTL from `CHARACTER_CACHE_TTL_MINUTES` (default 30);
  - `maxAge`: 90 days;
  - writing a page also writes `character:{id}` for each of its characters, so details open
    offline for everything in a cached list;
  - the box is opened on first use; parallel first calls share one opening `Future`.
- A record that is unreadable or has another `schemaVersion` is refetched, and eviction
  deletes old records, as for every cache (Local storage, Cache or user data; CHR-13).
- The API base URL comes from `RICK_AND_MORTY_API_BASE_URL`: it is the base of the whole API,
  not of the characters endpoint.
- Strategy:
  1. Fresh cache hit and not `forceRefresh` → return cache.
  2. Otherwise request the network; on success write to cache and return.
  3. On a network or server (5xx) failure → return stale cache if present, else the failure
     (CHR-11).

## Presentation

- `character_list`: the first load is `restartable`, refresh and the next page are `droppable`,
  and search has its own transformer: a debounce, then `switchMap`. Load, search and refresh
  all replace the first page, so older results are dropped by checking a generation counter in
  the state (CHR-5).
- `character_list` calls `TrackSearchUseCase` for a non-empty query after the debounce
  (CHR-17).
- `character_detail`: opening and retrying are one `CharacterDetailLoad` group with a
  `restartable` handler; only opening calls `TrackCharacterOpenedUseCase` (CHR-18). The route
  builder asks for the notification permission when the opened character loads, not after a
  failure or a retry (NTF-1).
- The image widget with its retries is
  `presentation/_shared/widget/image/character_image.dart`.
- The API host limits bursts of requests (HTTP 429, `retry-after: 10`), which fast scrolling
  reaches with an empty image cache.
