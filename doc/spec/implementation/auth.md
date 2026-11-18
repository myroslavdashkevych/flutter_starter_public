# Implementation: auth

**Code:** `domain/entity/app_user.dart`, `domain/repository/auth_repository.dart`,
`domain/use_case/auth` (account deletion: [profile.md](profile.md)), `data/auth`,
`presentation/auth`. Behavior:
[behavior/auth.md](../behavior/auth.md).

## Domain

- `AppUser` entity: `id`, `email` (nullable: future providers may not supply one).
- `AuthRepository`:
  - `Stream<AppUser?> authStateChanges()`
  - `Future<Result<AppUser>> signIn({email, password})`
  - `Future<Result<AppUser>> signUp({email, password})`
  - `Future<Result<void>> sendPasswordReset({email})`
  - `Future<Result<void>> signOut()`
  - `Future<Result<void>> reauthenticate({password})`
  - `Future<Result<void>> deleteAccount()`
- The contract is provider-agnostic so Google and Apple sign-in can be added later
  without changes to domain or features.
- Use cases: `WatchAuthStateUseCase` (the current user), `SignInUseCase`, `SignUpUseCase` and
  `SendPasswordResetUseCase`, which send the AUTH-8 events when the request succeeds, and
  `SignOutUseCase`. Account deletion: [profile.md](profile.md).

## Data

- `AuthFirebaseDataSource` (`data_source/auth_firebase_data_source.dart`) is the only class
  that calls `FirebaseAuth`, which `auth_firebase_module.dart` provides. It translates
  `FirebaseAuthException.code` into `AuthFirebaseException(failure)`
  (`mapper/auth_failure_mapper.dart`), and `AuthRepositoryImpl` returns that failure and
  logs only an unknown code. `network-request-failed` becomes `NetworkFailure`, like any
  other network error; every other code becomes `AuthFailure(reason)`:
  `invalidCredentials`, `emailAlreadyInUse`, `weakPassword`, `invalidEmail`,
  `userDisabled`, `tooManyRequests`, `requiresRecentLogin`, `unknown`.
- With email enumeration protection (default for new Firebase projects), wrong
  email and wrong password both arrive as `invalid-credential` → `invalidCredentials`.
- A password reset treats `user-not-found` as success (AUTH-7).
- `AuthFirebaseDataSource` implements `TokenProvider` for `backendDio`
  ([architecture.md](../architecture.md), Networking; where the token may go:
  [security.md](../security.md), Tokens).
- `mapper/app_user_mapper.dart` maps Firebase's `User` to `AppUser`.

## Presentation

- `AuthBloc` (global singleton): follows `WatchAuthStateUseCase` with `emit.forEach`, started
  by its constructor; states: `unknown`, `authenticated(user)`, `unauthenticated`. It only
  reacts: sign-out is requested by `ProfileBloc` through `SignOutUseCase`.
- `SignInBloc`, `SignUpBloc`, `ResetPasswordBloc` with form validation (AUTH-1 to AUTH-3).
  Their submit handler is `droppable`, so a repeated submit is ignored while one runs
  (AUTH-4). Their submit events leave the password out of `toString()` (OBS-7). They call
  the use case of their form, which sends the AUTH-8 event. Failures become messages in
  `presentation/_shared/l10n` ([architecture.md](../architecture.md), Result and failure).
