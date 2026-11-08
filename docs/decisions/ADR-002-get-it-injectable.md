# ADR-002: get_it + injectable for dependency injection

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

Classes across `domain`, `data` and `presentation` need their dependencies wired, per flavor,
without layers knowing about each other.

## Decision

Use `get_it` with `injectable` annotations. `getIt<T>()` is called only in `app/`; everything
else receives dependencies through constructors.

## Alternatives considered

- Manual DI, Riverpod DI: rejected; `get_it` + `injectable` support environments and scopes
  and scale with Clean Architecture.

## Consequences

- Registration is generated (`injection.config.dart`, not committed).
- `tool/check_imports.dart` rejects `getIt`, `GetIt` and `GetItHelper` outside `app/`.
- Details: [spec/architecture.md](../spec/architecture.md), Dependency injection.
