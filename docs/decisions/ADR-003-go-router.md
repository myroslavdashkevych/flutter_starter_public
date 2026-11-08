# ADR-003: go_router with typed routes; features navigate through callbacks

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

The app needs nested tabs, an auth redirect, in-app routes from notifications and screen view
analytics, while features must not import `app` or each other.

## Decision

- Use `go_router` with `go_router_builder`. The typed route tree lives in one file,
  `app/router/routes.dart`, because nested typed routes must be declared in one tree.
- Features never navigate by themselves: a page receives navigation callbacks, and the route
  builder implements them with typed routes. This keeps features free of `app` imports and of
  each other.
- The router has no `refreshListenable`: auth changes do not navigate; the Profile page
  follows them through `ProfileCubit`. A redirect would not close a pushed auth page anyway,
  because go_router passes it the location below that page.
- Screen views are sent by an own `ScreenViewObserver`, not `FirebaseAnalyticsObserver`, which
  needs a `FirebaseAnalytics` instance when the global `$appRoutes` is created.

## Alternatives considered

- auto_route: rejected; go_router is maintained by the Flutter team and has a stable API.

## Consequences

- Rules and details: [spec/architecture.md](../spec/architecture.md), Routing;
  behavior: [spec/features/navigation.md](../spec/features/navigation.md).
