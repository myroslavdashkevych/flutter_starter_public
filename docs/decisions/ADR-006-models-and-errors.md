# ADR-006: freezed models and an own sealed Result

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

Entities, DTOs and BLoC states need immutability, unions and JSON mapping. Repositories need a
way to return failures without throwing.

## Decision

- Models: `freezed` + `json_serializable`. Entities are freezed without JSON; DTOs are freezed
  with JSON; mappers live in `data`.
- Errors: an own sealed `Result<T>` (`Ok` / `Err` with a sealed `Failure`); repositories never throw.

## Alternatives considered

- dart_mappable, manual models: rejected; freezed + json_serializable have the largest
  ecosystem, unions and deep copyWith.
- fpdart: rejected; an own sealed `Result` works with Dart's native pattern matching and adds
  no FP dependency.

## Consequences

- freezed 4 rules apply ([spec/tech-stack.md](../spec/tech-stack.md), Compatibility notes).
- Details: [spec/architecture.md](../spec/architecture.md), Result and failure; Entities and
  DTOs.
