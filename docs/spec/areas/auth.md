# Area: auth

**Areas:** `domain/auth`, `data/auth`, `presentation/auth`. Behavior:
[features/auth.md](../features/auth.md).

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

## Data

- Firebase Auth implementation.
- `FirebaseAuthException.code` → `AuthFailure(reason)`:
  `invalidCredentials`, `emailAlreadyInUse`, `weakPassword`, `invalidEmail`,
  `userDisabled`, `tooManyRequests`, `requiresRecentLogin`, `network`, `unknown`.
- With email enumeration protection (default for new Firebase projects), wrong
  email and wrong password both arrive as `invalid-credential` → `invalidCredentials`.
- Implements `TokenProvider` for `backendDio` ([architecture.md](../architecture.md), Networking).

## Presentation

- `AuthBloc` (global singleton): listens to `authStateChanges`; states:
  `unknown`, `authenticated(user)`, `unauthenticated`. It only reacts: sign-out is
  called by `ProfileCubit` through `AuthRepository`.
- `SignInCubit`, `SignUpCubit`, `ResetPasswordCubit` with form validation (AUTH-1 to AUTH-3).
  They send the AUTH-8 events. Failures become messages in `presentation/_shared/l10n`
  ([architecture.md](../architecture.md), Result and failure).
