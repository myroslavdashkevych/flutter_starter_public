# Product

**Here:** what the product is and for whom: vision, users, scope, localization, non-goals and
what is not included yet.

**Not here:** behavior of each area ([behavior/](behavior/)); how it is built
([architecture.md](architecture.md)); packages ([tech-stack.md](tech-stack.md)).

## Vision

`flutter_starter` is a GitHub template for new Flutter apps (Android and iOS). It is a small
working demo app that shows the agreed architecture, stack and conventions end to end. Every
new project starts as a copy of it, so clarity and consistency matter more than feature count.

## Users

- **Developers** who start a new app from the template. They replace this product spec and
  the demo behavior specs with their own ([guide/new-project.md](../guide/new-project.md)).
- **End users of the demo app:** guests (no account) and signed-in users. Authentication is
  optional: characters, character details and settings work without signing in.

## Scope

What the demo app does (details in [behavior/](behavior/)):

- Optional email/password authentication with Firebase Auth: sign in, sign up, password reset.
- Bottom navigation with three tabs: Characters, Profile, Settings.
- Characters: a paginated, searchable list from the public Rick and Morty API, cached locally.
- Character details screen.
- Profile: sign-in entry for guests; account info, favorites, sign out and account deletion
  when signed in.
- Favorites for signed-in users.
- Settings: theme (system / light / dark), language (system / English / Ukrainian), a "Share
  usage data" switch and the privacy policy.
- Crashlytics, Analytics and push notifications (Android; iOS needs an APNs key).
- Accessibility basics on every screen: screen reader labels, tap target sizes, text contrast
  and large text ([behavior/accessibility.md](behavior/accessibility.md)).
- Native splash screen.
- Two flavors, `dev` and `prod`, each with its own Firebase project.

## Localization

Every user-facing string comes from ARB files in English (template) and Ukrainian.

## Non-goals

- Web and desktop targets.

## Not included yet

- An own backend: account deletion removes the Firebase Auth account and local favorites only
  ([behavior/profile.md](behavior/profile.md)).
- Google Sign-In and Sign in with Apple (deferred, [tech-stack.md](tech-stack.md), Deferred).
- Native deep links (Android intent filters, iOS URL schemes).
- iOS push delivery: the code is present, but an APNs key is not configured.
