# ADR-011: supporting tools and the demo data source

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

Smaller choices made with the stack, each with a stated reason.

## Decision

| Area | Choice | Reason |
|---|---|---|
| Localization | gen-l10n | Official, no extra dependency |
| Logging | talker | BLoC/Dio integrations, in-app log screen |
| Mocks | mocktail | No codegen in tests |
| Lints | flutter_lints + extra rules | Less noise, fewer dependencies |
| Images | cached_network_image_ce | The original is unmaintained; the CE fork uses hive_ce, which is already in the stack |
| Items source | Rick and Morty API | Stable, no key, server pagination and search, images |

## Alternatives considered

- Localization: slang, easy_localization.
- Logging: logger.
- Mocks: mockito.
- Lints: very_good_analysis.
- Images: cached_network_image.
- Items source: DummyJSON, JSONPlaceholder.

## Consequences

- Package list: [spec/tech-stack.md](../spec/tech-stack.md).
