# ADR-008: local data is either a cache or user data

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

Local stores differ in what losing them costs. A cache can be fetched again; data the user
created has no other copy.

## Decision

Every Hive store is one of two kinds, decided before writing the data source by asking: **if
this data is lost, can it be fetched again?** Yes: a cache. No: user data. When unsure, treat
it as user data; keeping too much is safer than losing what the user made.

- Caches implement `ExpiringCache` and are deleted automatically (records older than their
  `maxAge`, with another `schemaVersion` or unreadable).
- User data is never deleted automatically, only by a user action.

## Alternatives considered

None recorded.

## Consequences

- The full comparison table and rules:
  [spec/architecture.md](../spec/architecture.md), Cache or user data.
- User data of a signed-in user is deleted with the account
  ([spec/areas/profile.md](../spec/areas/profile.md)).
