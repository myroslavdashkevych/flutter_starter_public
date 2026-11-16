# Onboarding

**Here:** how to find your way around the starter as a person: the mental model, one request
traced through the code, the order to read the docs in, how a change goes, and where common
things belong.

**Not here:** rules (each lives in one document, linked below); running the app (the root
`README.md`, Quick start); setting up tools and Firebase ([setup.md](setup.md)).

## The mental model

The app has three layers, and dependencies point inward:

```
presentation  ──>  domain  <──  data
 (UI, Blocs)     (pure Dart)   (APIs, storage)
```

- **domain** says what the app can do: entities, repository contracts and use cases. It knows
  no Flutter, no HTTP and no storage, so it is the easiest part to read first.
- **data** implements the contracts: it calls APIs and storage and turns their answers into
  entities and `Result` values. Nothing above it ever sees an exception or a DTO.
- **presentation** shows state and sends events. A Bloc reaches data only through a use
  case, never directly.
- **app** wires everything together: dependency injection, routes and startup.

The rules behind this picture: [architecture.md](../spec/architecture.md), Principles and
Terms.

## One request, end to end

Opening the Characters tab, from the route to the screen:

1. `app/router/routes.dart`: `CharacterListRoute` creates `CharacterListBloc` through DI,
   adds `CharacterListLoadRequested` and builds `CharacterListPage`. The page gets
   `onCharacterSelected` as a callback, so it never navigates by itself.
2. `presentation/character_list/bloc/character_list_bloc.dart`: the handler calls
   `GetCharacterPageUseCase` and emits a new `CharacterListState`.
3. `domain/use_case/character/get_character_page_use_case.dart`: trims the search query and
   calls `CharacterRepository.getPage`, a contract in `domain/repository/`.
4. `data/character/character_repository_impl.dart`: returns a fresh cached page from
   `CharacterHiveDataSource`, or asks `CharacterApiDataSource` (retrofit), stores the answer
   and returns it. A network or server failure falls back to a stale cached page, if there is
   one.
5. Back up: the result arrives as `Ok` or `Err`, the Bloc emits it, and the page rebuilds.
   A tap on a tile calls `onCharacterSelected(id)`, and the route builder opens
   `CharacterDetailRoute`.

What this flow must do is in [behavior/character.md](../spec/behavior/character.md); how the
cache works is in [area/character.md](../spec/area/character.md).

## Reading order

1. [product.md](../spec/product.md): what the app is and what it is not.
2. One behavior file, for example [behavior/character.md](../spec/behavior/character.md):
   requirements with IDs (`CHR-1`) and their scenarios. Tests carry these IDs in their
   names, so a search for an ID finds its tests.
3. The matching area file, for example [area/character.md](../spec/area/character.md): the
   contracts, data sources and storage behind that behavior.
4. [architecture.md](../spec/architecture.md) when you write code, and
   [code-style.md](../spec/code-style.md) when you review it.
5. [security.md](../spec/security.md): what must never reach the repository, logs, crash
   reports or analytics, and the protections the starter decided not to use.

[reading-rule.md](../reading-rule.md) is written for AI agents: it tells them which
documents to read for which files. You can skip it.

## How a change goes

Every change has a size, and the size sets how much process it needs
([doc/README.md](../README.md), Scale by risk, which decides):

- **S** needs no plan folder: a bug fix that restores specified behavior, a typo, or a
  refactor without behavior change.
- **M** and **L** start with a `proposal.md` (why, and the exact new requirements) and a
  `tasks.md` plan: every behavior change, a structural refactor, a new feature.

Every change gets its own branch and pull request. Before the pull request, the
`change-reviewer` agent reviews it, and the checks of [doc/README.md](../README.md),
Verification, run; CI runs those checks again ([setup.md](setup.md), CI).

Dependabot pull requests follow a rule of their own ([doc/README.md](../README.md), Changes;
[setup.md](setup.md), Dependabot).

## Where does it go?

| You want to add | Start here |
|---|---|
| A screen | [architecture.md](../spec/architecture.md), Adding a feature, which lists the steps in order; the screen entry: [doc/README.md](../README.md), Screens |
| A call to an API | [architecture.md](../spec/architecture.md), Networking: search the data sources first, since every remote call has one place; where the auth token may go: [security.md](../spec/security.md), Tokens |
| A secret, an API key or a config value | [security.md](../spec/security.md), Secrets and the repository |
| Stored data | [architecture.md](../spec/architecture.md), Local storage: decide first whether it is a cache or user data |
| Logging, storing or sending personal data | [security.md](../spec/security.md), Personal data and Local storage |
| A package | [tech-stack.md](../spec/tech-stack.md) and [architecture.md](../spec/architecture.md), External packages; a `pubspec.yaml` change needs approval. Updates of existing packages come from Dependabot ([setup.md](setup.md), Dependabot) |
| A text on screen | [architecture.md](../spec/architecture.md), Localization, and [doc/README.md](../README.md), Verification |
| A decision worth explaining later | An ADR in `doc/decision/` ([doc/README.md](../README.md), ADRs) |

## Working with an AI agent

`CLAUDE.md` holds the rules for Claude Code, and `.claude/` holds its settings and hooks.
What to expect:

- The agent writes the plan (`tasks.md`) and waits for your approval before it implements an
  M or L change.
- It never reads the Firebase configuration files; it prepares the `flutterfire` commands,
  and you run them ([setup.md](setup.md), Firebase).
- When a hook or a permission rule blocks a command, the agent stops and tells you instead of
  finding a way around it. The project's `.claude/settings.json` denies a few actions, the
  reviewer's own hook limits its commands, and any other block comes from your personal
  Claude Code settings.
- The `change-reviewer` agent only reports; the session that made the change fixes the
  findings ([setup.md](setup.md), Change reviewer).
