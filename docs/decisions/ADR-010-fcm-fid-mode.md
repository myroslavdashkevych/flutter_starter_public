# ADR-010: FCM in Firebase Installation ID (FID) mode

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

`firebase_messaging` registration tokens from `getToken` and `onTokenRefresh` are deprecated.

## Decision

Use `register()` and `onRegistered` from `firebase_messaging` with
`firebase_messaging_installation_id_enabled` in `AndroidManifest.xml`. The registration id is
the Firebase Installation ID (FID).

## Alternatives considered

- `getToken` / `onTokenRefresh`: deprecated, not used.

## Consequences

- A backend must send with the target `fid`.
- Check any third-party push service for FID support before adopting it.
- The starter only logs the FID; a real app must send it to its backend.
- Details: [spec/areas/notifications.md](../spec/areas/notifications.md);
  [guides/store-release.md](../guides/store-release.md), Push notifications.
