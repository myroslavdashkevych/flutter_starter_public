# ADR-004: dio + retrofit for HTTP

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

The app calls a third-party public API. The starter has no own backend yet, but `backendDio`
is registered and tested as the pattern for one.

## Decision

- Use `dio` with `retrofit` clients.
- Two Dio clients: `publicDio` for third-party public APIs, with no auth header, and
  `backendDio` for the app's own backend, with `AuthInterceptor`. The Firebase ID token is never
  attached to a third-party API.

## Alternatives considered

- http, chopper: rejected; dio has interceptors (auth refresh, logging) and retrofit gives
  declarative clients.

## Consequences

- Retry behavior: [ADR-005](ADR-005-retry-policy.md).
- Details: [spec/architecture.md](../spec/architecture.md), Networking.
