# Favorites

Favorites belong to signed-in users. Implementation: [areas/favorites.md](../areas/favorites.md).

## Requirements

### Toggle

- **FAV-1** A signed-in user sees a favorite toggle on each item list tile and in the item
  details app bar. Tapping it adds or removes the item.
  - GIVEN a signed-in user WHEN the user taps the toggle on a tile THEN the item becomes a
    favorite and the toggle shows it
  - WHEN the user taps it again THEN the item is no longer a favorite
- **FAV-2** A guest sees no favorite toggles and no **Favorites** entry on the profile.
  - GIVEN a guest WHEN the items list or item details open THEN no toggle is shown
  - GIVEN a guest WHEN the Profile tab opens THEN there is no **Favorites** entry
- **FAV-3** A change shows at once on every screen.
  - GIVEN item 5 is open in details and listed in favorites WHEN the user removes it in
    details THEN the favorites list no longer shows it, without a reload
- **FAV-4** A failed toggle shows a SnackBar.
  - WHEN toggling fails THEN a SnackBar shows the failure message

### Favorites page

- **FAV-5** The favorites page lists the favorites newest first, from the stored snapshots.
  - GIVEN favorites A then B were added WHEN the page opens THEN B is shown above A
- **FAV-12** While the auth state or the favorites are not known yet, the favorites page shows
  a progress indicator.
  - WHEN the favorites page opens before the auth state is known THEN a progress indicator is
    shown
- **FAV-13** With no favorites, the favorites page shows a hint.
  - GIVEN no favorites WHEN the page opens THEN the hint is shown
  - WHEN the user removes the last favorite THEN the hint is shown
- **FAV-14** Tapping a favorite opens `/profile/favorites/:id`.
  - WHEN the user taps a favorite THEN its details open inside the Profile tab
- **FAV-15** Removing the mark on a favorite removes its tile at once.
  - WHEN the user removes the mark on a tile THEN the tile disappears at once
- **FAV-6** A guest who reaches the favorites page sees "Sign in to save favorites" and
  **Sign in**, which opens `/sign-in`. After signing in the user lands on `/profile`, like
  every sign-in (NAV-6).
  - GIVEN a guest WHEN `/profile/favorites` opens THEN the sign-in prompt is shown
  - WHEN the guest signs in from there THEN `/profile` is shown

### Storage

- **FAV-7** Favorites are stored on the device and persist across launches. They are never
  deleted automatically, only when the user removes a favorite or deletes the account (PRF-6).
  - GIVEN a user has favorites WHEN the app restarts THEN the same favorites are shown
- **FAV-16** Favorites belong to one user. After sign-out none are shown; when the user changes,
  the previous user's favorites are hidden at once and come back when that user signs in again.
  - GIVEN user A has favorites WHEN A signs out THEN no favorites are shown
  - WHEN user B signs in on the same device THEN only B's favorites are shown
  - WHEN A signs in again THEN A's favorites are back
- **FAV-8** A stored favorite that cannot be read (another schema version or broken data) is
  skipped and kept, so a later version can migrate it. Toggling that item overwrites it.
  - GIVEN a favorite with an unknown schema version WHEN the list loads THEN it is not shown
    and stays stored
- **FAV-9** If the favorites storage cannot be opened, the list is empty; the next toggle tries
  to read it again and fails with a message if that fails too.
  - GIVEN the storage cannot be opened WHEN the page opens THEN the list is empty
  - WHEN the user toggles and the storage still cannot be opened THEN the failure is shown (FAV-4)

### Details of a favorite

- **FAV-10** `/profile/favorites/:id` loads the item through the items source (ITM-10, ITM-11),
  not from the snapshot. If the item no longer exists, the message is shown without a retry, with
  **Remove from favorites**, which removes the favorite and returns to the list. Any other
  failure shows the usual retry. (At `/items/:id` the retry is always shown, ITM-15.)
  - GIVEN a favorite whose item was deleted on the server WHEN its details open THEN the not
    found message and **Remove from favorites** are shown, without retry
  - WHEN the user taps **Remove from favorites** THEN the favorite is removed and the list is shown
  - WHEN details fail for another reason THEN the error with retry is shown

### Analytics

- **FAV-11** `add_to_wishlist` (standard event name) and `remove_from_wishlist` (custom event),
  with `item_id`, are sent when a toggle succeeds.
  - WHEN adding succeeds THEN `add_to_wishlist` is sent with the item id
  - WHEN removing succeeds THEN `remove_from_wishlist` is sent with the item id
  - WHEN a toggle fails THEN no event is sent

## Screens

### SCR-8 Favorites

- Route: `/profile/favorites`.
- States: loading (FAV-12); guest prompt (FAV-6); empty hint (FAV-13); list (FAV-5, FAV-14,
  FAV-15).
- Design: pending

The details of a favorite use SCR-6 ([items.md](items.md)) with the FAV-10 states.

Retired: none
