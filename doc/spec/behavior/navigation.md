# Navigation

Routing rules for code: [architecture.md](../architecture.md), Routing.

## Route map

```
/sign-in                     # pushed over the shell from the Profile tab
/sign-up                     # pushed from /sign-in
/reset-password              # pushed from /sign-in
StatefulShellRoute (bottom navigation, presentation/home_shell)
  ├─ /character-list              # character_list, the initial location
  │    └─ /character-list/:id     # character_detail
  ├─ /profile                # profile: guest or account view
  │    └─ /profile/favorite-list       # favorite_list
  │         └─ /profile/favorite-list/:id  # character_detail, the same page as /character-list/:id
  └─ /settings               # settings
         └─ /settings/logs   # TalkerScreen, dev flavor only
```

## Requirements

- **NAV-1** The app starts on `/character-list`.
  - WHEN the app is launched THEN the Characters tab is shown at `/character-list`
- **NAV-2** Bottom navigation shows three tabs in this order: **Characters**, **Profile**,
  **Settings**.
  - WHEN the home shell is shown THEN the tabs read Characters, Profile, Settings from left to
    right
- **NAV-3** Each tab keeps its own navigation stack.
  - GIVEN character details are open in the Characters tab WHEN the user switches to Settings
    and back THEN character details are still shown
- **NAV-4** Authentication is optional: characters, character details and settings work without
  signing in, and no route requires a signed-in user.
  - WHEN a guest opens `/character-list`, `/character-list/:id` or `/settings` THEN the page is
    shown without a sign-in step
  - WHEN a guest reaches `/profile/favorite-list` THEN that page shows a sign-in prompt (FAV-6)
- **NAV-5** A signed-in user who navigates to an auth route is redirected to `/profile`. No
  other redirect depends on the auth state.
  - GIVEN the user is signed in WHEN they navigate to `/sign-in`, `/sign-up` or
    `/reset-password` THEN `/profile` is shown
- **NAV-6** After a successful sign-in or sign-up the user lands on `/profile`; the whole auth
  stack is removed and the other tabs keep their stacks.
  - GIVEN the user opened `/sign-in` and then `/sign-up` WHEN sign-up succeeds THEN `/profile`
    is shown and back does not return to an auth page
- **NAV-7** `/settings/logs` exists only in the `dev` flavor.
  - GIVEN the `prod` flavor WHEN `/settings/logs` is opened THEN `/settings` is shown
- **NAV-8** Native deep links (Android intent filters, iOS URL schemes) are not configured. In-app
  routes from notifications are covered by NTF-6.
  - WHEN the app is opened through a URL scheme or an intent filter THEN nothing is routed,
    because none is registered

## Screens

### SCR-4 Home shell

- Route: `StatefulShellRoute` (`presentation/home_shell`), branches `/character-list`, `/profile`, `/settings`.
- States: one per selected tab (NAV-2, NAV-3).
- Design: pending

## Implementation notes

- NAV-6 is done by the route builder calling `ProfileRoute().go(context)`. The redirect cannot
  do this: go_router does not see a pushed route in the location it passes to a redirect.
- The redirect (`app/router/auth_redirect.dart`) and what it reads:
  [architecture.md](../architecture.md), Routing.

Retired: none
