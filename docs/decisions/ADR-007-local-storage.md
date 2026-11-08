# ADR-007: hive_ce with JSON strings; SharedPreferencesAsync for settings; no secure storage

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

The app stores an API response cache, per-user favorites and a few settings. Search and
pagination are server-side.

## Decision

- Records go to hive_ce `LazyBox`es. Local data is a response cache and per-user favorites
  read as a whole, so no local query engine is needed.
- Hive values are JSON **strings** (`jsonEncode` of a DTO's `toJson()`), not maps. Hive returns
  nested maps as `Map<dynamic, dynamic>`, which `fromJson` cannot take without deep casting;
  strings avoid that. No Hive type adapters and no `hive_ce_generator`.
- Settings go to `SharedPreferencesAsync`: few scalar values, and its async API is isolate-safe.
- No secure storage: Firebase Auth persists and refreshes the session itself.

## Alternatives considered

- drift, isar, objectbox: rejected while search and pagination are server-side. Revisit with
  drift if offline querying is needed.
- Hive for settings: rejected for the reasons above.
- flutter_secure_storage: not needed (above).
- `hive_ce_generator`: left out; one less generator to keep compatible with the analyzer. Add
  it back only with user approval if Hive adapters are ever needed.

## Consequences

- Every stored value is wrapped in an envelope with `schemaVersion`.
- Details: [spec/architecture.md](../spec/architecture.md), Local storage.
