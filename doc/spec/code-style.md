# Code style

How code is written inside a file: names, the order of class members, methods, widgets and
language usage.

**Not here:** where a file lives, what it may import and which patterns a layer uses
([architecture.md](architecture.md)); the change workflow and test names
([doc/workflow.md](../workflow.md)); packages ([tech-stack.md](tech-stack.md)).

## Sources

Every rule names its source in brackets:

| Mark | Source | Decides |
|---|---|---|
| (Effective Dart) | [Effective Dart](https://dart.dev/effective-dart) | Language usage and names |
| (Flutter style guide) | [Style guide for Flutter repo](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md) | What Effective Dart leaves open: class member order, callback names |
| (Flutter docs) | [Performance best practices](https://docs.flutter.dev/perf/best-practices), Control build() cost | When a widget is split |
| (project) | This project's choice; the reason follows the rule | Everything else |

- When two sources disagree, the higher row wins, unless a `(project)` rule names the rule it
  makes an exception to (Callbacks). [architecture.md](architecture.md) wins over
  all of them on structure: for example, mappers and `context.l10n` are extensions, although
  the Flutter style guide avoids extensions.
- A rule that a lint or `dart format` checks is not repeated here (Lints).

## Formatting

- `dart format` with the default 80 columns decides all layout, including trailing commas.
  Code is never aligned by hand. (project: one formatter, no style debates)

## Naming

### Identifiers

- `UpperCamelCase` for types, extensions and enum types; `lowerCamelCase` for everything else,
  constants and enum values included, without a `k` prefix. (Effective Dart)
- Acronyms and abbreviations longer than two letters are capitalized as words: `ApiClient`,
  `HttpStatus`, `userId`; two-letter acronyms stay upper case: `IOSink`. (Effective Dart)
- No prefix letters: no `I` for interfaces, no `m` for fields. A leading `_` means private and
  nothing else. (Effective Dart)
- One word per concept across the code base: a term from [architecture.md](architecture.md),
  Terms, keeps its meaning in names. (Effective Dart)
- The most descriptive noun comes last: `pageCount`, `CharacterTile`. (Effective Dart)
- A boolean is named positively, as a non-imperative verb phrase: `isLoadingMore`, `hasMore`,
  `canRetry`; never `isNotX` or `disabled`. (Effective Dart)
- A method that mainly does something is an imperative verb (`refresh`, `signOut`); a member
  that mainly returns a value is a noun or a getter (`displayName`), never `getX`. A method
  that converts to a new object is `toX()` (`toEntity`). (Effective Dart)

### Callbacks

- A callback parameter or field is `onFoo`; its type is `ValueChanged<T>`, `VoidCallback` or a
  `FooCallback` typedef; the method that handles it is `_handleFoo`, whether it is passed
  directly or called from a closure (`onTap: () => _handleSignOutTap(context)`). A method is
  never named `onFoo`. (Flutter style guide)
- Exception to the rule above: a Bloc event handler is `_on<Event>` (`_onSearchChanged`).
  (project: the bloc library convention, read by every Bloc user)

### Bloc events and states

- An event is `<Bloc><Subject><PastTense>`, a fact that already happened: `Started`,
  `Requested`, `Changed`, `Submitted`, `Tapped` (`CharacterListNextPageRequested`,
  `SettingsThemeChanged`). (project: the bloc library naming conventions)
- A state is `<Bloc>State`; its status enum is `<Bloc>Status` (`CharacterListStatus`).
  (project: the Bloc's name finds all its types)

### Files and types

A class in `data` that wraps an SDK, a client or a storage names that technology; a class that
only combines other classes is named after its port with `Impl` (project: the name says what
a class depends on):

- `CharacterHiveDataSource`, `AuthFirebaseDataSource`: a data source wraps one technology.
- `FirebaseAnalyticsService`: a service implementation wraps the SDK itself, with no data
  source. Its file is named after the SDK and a port of the service folder; the checker
  requires the class to implement that port.
- `CharacterRepositoryImpl`: a repository combines its data sources and names no technology.

| Kind | Pattern |
|---|---|
| Files | `snake_case.dart` |
| Entity | `character.dart` -> `Character` |
| DTO | `character_dto.dart` -> `CharacterDto` |
| Repository contract | `character_repository.dart` -> `CharacterRepository` |
| Repository impl | `character_repository_impl.dart` -> `CharacterRepositoryImpl` |
| Data source | `<area>_<type>_data_source.dart` -> `<Area><Type>DataSource`: `character_hive_data_source.dart` -> `CharacterHiveDataSource` |
| Retrofit client | `character_api_data_source.dart` -> `CharacterApiDataSource` (type `api`) |
| Data source exception | `auth_firebase_exception.dart` -> `AuthFirebaseException` |
| Service implementation | `<sdk>_<port>.dart`: `firebase_analytics_service.dart` -> `FirebaseAnalyticsService` |
| DI module of an area | `<area>_<type>_module.dart`: `auth_firebase_module.dart` -> `AuthFirebaseModule` |
| DI module in `data/_shared` | `<sdk>_module.dart`: `hive_module.dart` -> `HiveModule`, `firebase_analytics_module.dart` -> `FirebaseAnalyticsModule` |
| DI module outside `data` | `<what it sets up>_module.dart`: `network_module.dart` -> `NetworkModule` |
| Mapper | `<model>_mapper.dart`: `character_mapper.dart`, extensions `<Source>Mapper` |
| Use case | `<group>/<verb>_<noun>_use_case.dart`: `character/get_character_page_use_case.dart` -> `GetCharacterPageUseCase` (callable via `call`) |
| Analytics use case | `<group>/track_<event>_use_case.dart` -> `TrackSearchUseCase` |
| Analytics event | `AnalyticsEvent.<pastTense>` -> `<PastTense>AnalyticsEvent`: `AnalyticsEvent.searched(term:)` -> `SearchedAnalyticsEvent` |
| Bloc | `character_list_bloc.dart`, `character_list_event.dart`, `character_list_state.dart` |
| Page | `character_list_page.dart` -> `CharacterListPage` |
| Screen name, route path | `character_list` -> `/character-list` (Singular names) |
| Test | same path under `test/`, suffix `_test.dart` |

### Singular names

(project: one form of each name, so a search finds every use)

- **Every folder and file name is singular**, in `lib/`, `test/` and `doc/` (the change folder
  slugs too), except a collection name (below), and so is every name formed from an area or
  feature: folders by kind (`entity/`, `repository/`, `use_case/`, `data_source/`, `model/`,
  `mapper/`, `service/`, `wrapper/`, `component/`, `widget/`, `page/`, `const/`), files
  (`failure_message.dart`, `auth_validator.dart`), classes, use case groups, spec files, Hive
  box names, prefs keys, config keys, ARB key prefixes and screen names (`character`,
  `favorite`, `notification`; `character_list`, `favorite_list`; `CharacterRepository`,
  `character_cache`, `CHARACTER_CACHE_TTL_MINUTES`, `characterListEmpty`).
- **Exceptions**, in one list, `_pluralNames` in `tool/check_imports.dart`:
  - by convention: `settings` (the area stays plural, with everything formed from it:
    `SettingsRepository`, `settings.theme`), `utils` and `prefs`;
  - not a plural: `analytics` is an uncountable noun that only ends in `s`.

  The file `app/router/routes.dart` keeps its name: it is the exception of
  [architecture.md](architecture.md), Principles, because go_router_builder needs the route
  tree in one file.
- **A collection may be plural** when the plural is not at the start of the name
  (`UserFavorites`, `WatchFavoritesUseCase`, `Paginated.items`,
  `watch_opened_notifications_use_case.dart`). Such a name is not on the list above, because
  the checker flags only a name that starts with the plural of an area. A package name such as
  `flutter_local_notifications` is not ours to change.
- **ADR file names** in `doc/decision/` are exempt: the slug after the ID is the title of the
  decision, in plain words (`ADR-001-offline-first-sync.md`), and never changes.
- **A route path** names its screen: each static segment is the screen name in kebab-case
  (`character_list` -> `/character-list`, `sign_in` -> `/sign-in`); a details route adds only
  `:id` (`/character-list/:id`).
- Checked by `tool/check_imports.dart`: a folder under `lib/` or `test/` whose name ends in `s`
  is on the list above; an area name (from its contract
  `domain/repository/<area>_repository.dart`) does not end in `s` unless listed; no folder or
  file in `lib/` starts with the plural of an area (`characters_module.dart`,
  `presentation/characters_list`); each named route in `app/router/routes.dart` ends in its
  screen name in kebab-case. The plural of an area is built as `<area>s` only, so a singular
  word that ends in `s` (`status`) needs `_pluralNames`, and an irregular plural
  (`categories`) is not detected. File names are not checked for the plural, but public type
  names follow file names ([architecture.md](architecture.md), Principles), so classes are
  covered. Identifiers inside files, ARB keys, storage and config keys, screen names and every
  name in `doc/` are checked in review.

## Class member order

Members follow this order, with a blank line between groups (Flutter style guide):

1. Constructors: the unnamed one first, then named, then factory constructors.
2. Final fields set by the constructor.
3. Other instance fields.
4. Static constants and static methods.
5. Getters and setters.
6. Lifecycle methods in the order they run: `initState`, `didChangeDependencies`,
   `didUpdateWidget`, `dispose`.
7. Other methods; a method comes before the private methods it calls.
8. `build` in `Widget` and `State` classes.
9. `operator ==`, `hashCode`, `toString`.

- A Bloc registers its handlers in the constructor; the handlers follow in the order of their
  `on<E>` calls. (project: the constructor is the table of contents of the Bloc)

## Methods

(project: a method reads as one step of its caller)

- A method does one thing at one level of abstraction.
- A block becomes its own method when it needs a comment to say *what* it does, when it is
  repeated, or when it nests deeper than two levels.
- Preconditions return early instead of wrapping the body in `if`.
- A parameter whose meaning is not clear from the call is named. (project: the call site
  reads without opening the declaration)

## Widgets

- A part of a widget tree is extracted into a widget class, never into a function or a method
  that returns a widget: a class can be `const`, rebuilds on its own and shows in the widget
  inspector. (Flutter docs)
- A `build` that grows long is split by meaning and by what makes each part change, so a
  state change rebuilds only the part that depends on it. (Flutter docs)
- Where an extracted widget lives (project: the narrowest place that works):
  - used by one file: a private class `_Name` in that file, below the public widget;
  - used by several files of a feature: a public widget in the feature's `widget/` folder;
  - used by several features: [architecture.md](architecture.md), Inside
    `presentation/_shared`.
- A local variable inside `build` that names a widget is allowed. (project: it names a part
  of the tree without the cost of a class, and rebuilds with `build` anyway)
- Spacing comes from `AppSpacing` (`presentation/_shared/theme/const/app_spacing.dart`),
  colors from `Theme.of(context).colorScheme` or, for the roles it lacks (`success`,
  `warning`), from `Theme.of(context).appColor`, text styles and their fonts from
  `textTheme`; no literal design values in widgets. `AppColor` and `AppFont` are read only by
  the theme files (checked in review). (project: the theme owns the look,
  [doc/workflow.md](../workflow.md), Source of truth)

## Language usage

- Branching on a sealed type or an enum uses a `switch` expression or statement with patterns.
  (project: the analyzer reports a missing case when a variant is added)
- `!` is used only where the state guarantees the value (a status that implies it); otherwise
  the value is checked. (project: a `!` that can fail is a crash the analyzer cannot see)
- `async`/`await` instead of raw `then` chains. (Effective Dart)
- No `dynamic` unless static checking must be disabled, such as decoded JSON before
  `fromJson`. (Effective Dart)
- Types are written on public members and fields whose type is not obvious; local variables
  are inferred. (Effective Dart)
- Strings are built with interpolation, not `+`. (Effective Dart)
- A comment says *why*, not what the code does. A `///` doc comment is written where the name
  and the signature do not say everything. Both are in English. (project: the code says what;
  a comment that repeats it goes stale)

## Lints

`analysis_options.yaml` adds rules that check this file: `sort_constructors_first`,
`sort_unnamed_constructors_first`, `directives_ordering` (with `always_use_package_imports`),
`avoid_positional_boolean_parameters`, `prefer_single_quotes`, `prefer_final_locals`,
`always_declare_return_types`. The rest of `flutter_lints` applies as is.
