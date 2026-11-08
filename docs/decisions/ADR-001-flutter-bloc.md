# ADR-001: flutter_bloc for state management

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

The starter needs one state management approach that every project copies.

## Decision

Use `flutter_bloc`. `Cubit` for simple state; `Bloc` when events need transformers
(debounce, droppable, restartable).

## Alternatives considered

- Riverpod, Provider, GetX: rejected in favor of the predictable event/state model of BLoC,
  its strong testing support and the team's experience with it.

## Consequences

- States are freezed classes; BLoCs never see a `BuildContext`
  ([spec/architecture.md](../spec/architecture.md), State management).
- BLoCs are tested with `bloc_test`.
