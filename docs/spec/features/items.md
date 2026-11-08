# Items (list and details)

Characters from the Rick and Morty API. The `items` area is a demo and is expected to be
replaced in real projects. Implementation: [areas/items.md](../areas/items.md).

## Requirements

### List

- **ITM-1** Each tile shows the image, name, species and status. Tapping a tile opens `/items/:id`.
  - WHEN the user taps a tile THEN the details of that item open at `/items/:id`
- **ITM-2** A search field above the list searches by name on the server, 400 ms after the
  last keystroke. A new query restarts pagination.
  - WHEN the user types a name and stops for 400 ms THEN the list shows the first page of
    matching items
  - WHEN the user changes the query while pages are loaded THEN the list restarts from page 1
- **ITM-3** The next page loads when 80% of the list is scrolled.
  - WHEN the user scrolls past 80% of the loaded list and more pages exist THEN the next page
    loads, with a loading-more indicator
- **ITM-4** Pull-to-refresh reloads page 1 from the network, bypassing a fresh cache.
  - WHEN the user pulls to refresh and the request succeeds THEN page 1 is replaced
- **ITM-19** A failed refresh keeps the list and shows the failure message in a SnackBar once.
  - WHEN the refresh fails and no cached data exists THEN the list stays and a SnackBar shows
    the failure once
- **ITM-5** A new search or a refresh makes older requests obsolete: a result that arrives
  afterwards is dropped.
  - GIVEN a request for query "a" is running WHEN the user searches for "ab" THEN a late
    result for "a" never replaces the list
- **ITM-6** A search with no results shows the empty state, not an error.
  - WHEN the user searches for a name with no matches THEN the empty state is shown
- **ITM-7** A failed first load shows an error with a retry button; a failed next page shows
  an inline retry below the loaded items.
  - WHEN the first page fails and nothing is cached THEN an error with retry is shown
  - WHEN a next page fails THEN the loaded items stay and an inline retry is shown
- **ITM-8** A list request rejected because the API host limits bursts (HTTP 429 with
  `retry-after: 10`) is not retried automatically: the failure with its retry button appears at once.
  - WHEN a list request gets HTTP 429 with `retry-after: 10` THEN the error with retry is shown
    without an automatic retry
- **ITM-9** A failed image stays blank and is retried up to 3 times, 10 seconds apart; only then
  it shows an error icon.
  - WHEN an image fails to load THEN the tile stays blank and the image is retried after 10 s
  - WHEN the third retry fails THEN an error icon is shown

### Offline and cache

- **ITM-10** Data fetched within the cache TTL (`ITEMS_CACHE_TTL_MINUTES`, default 30 minutes)
  is shown without a network request, unless the user refreshes.
  - GIVEN page 1 was fetched 10 minutes ago WHEN the list opens THEN page 1 comes from the
    cache without a request
- **ITM-11** On a network or server (5xx) failure, cached data is shown even when it is older
  than the TTL; the failure is shown only when nothing is cached. A refresh without a
  connection therefore shows the cached data, not an error.
  - GIVEN page 1 is cached WHEN the user refreshes offline THEN the cached page stays and no
    error state is shown
- **ITM-12** Details open offline for every item of a cached list page.
  - GIVEN a list page was loaded WHEN the user opens one of its items offline THEN the details
    are shown from the cache
- **ITM-13** Cached data older than 90 days is deleted after the first frame of a launch; until
  then it can still be shown offline.
  - GIVEN a page was cached 91 days ago WHEN the app launches THEN the record is deleted after
    the first frame

### Details

- **ITM-14** Item details show all item fields (name, status, species, gender, origin,
  location, episode count) and a large image.
  - WHEN details load THEN all fields and the large image are shown
- **ITM-15** A failed details load shows an error with a retry button. At `/items/:id` the retry
  is always shown, including for an item that does not exist.
  - WHEN details fail at `/items/:id` THEN an error with retry is shown
- **ITM-16** An item that no longer exists on the server is reported as not found, even when a
  stale copy is cached.
  - GIVEN item 5 is cached WHEN the server answers 404 for item 5 THEN the not found message is
    shown, not the cached copy

### Analytics

- **ITM-17** `search` (standard event, parameter `search_term`) is sent for a non-empty query
  after the debounce.
  - WHEN the debounce ends with a non-empty query THEN `search` is sent with that term
  - WHEN the query is empty THEN no event is sent
- **ITM-18** `select_content` is sent when an item is opened, not on a retry.
  - WHEN the user opens an item THEN `select_content` is sent once
  - WHEN the user taps retry on the details error THEN no event is sent

## Screens

### SCR-5 Items list

- Route: `/items` (initial location, first tab).
- States: initial loading; list (ITM-1, ITM-2, ITM-3); empty, for no results or nothing loaded
  (ITM-6); error with retry (ITM-7, ITM-8); loading more (ITM-3); error while loading more with
  inline retry (ITM-7). Signed-in users see a favorite toggle on each tile (FAV-1).
- Design: pending

### SCR-6 Item details

- Routes: `/items/:id` and `/profile/favorites/:id` (the same page).
- States: loading; loaded (ITM-14); error with retry (ITM-15); at `/profile/favorites/:id`,
  not found with **Remove from favorites** (FAV-10). Signed-in users see a favorite toggle in
  the app bar (FAV-1).
- Design: pending

## Implementation notes

- ITM-6: the API answers an empty search, and a page past the last one, with HTTP 404 and an
  error body; a list 404 is mapped to an empty page and not cached.
- ITM-8: the retry limit for `Retry-After` is 3 s ([areas/network.md](../areas/network.md),
  RetryInterceptor), so `retry-after: 10` is never waited for. Fast scrolling with an empty image
  cache reaches the host's burst limit.

Retired: none
