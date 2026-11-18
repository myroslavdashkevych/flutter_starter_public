# Implementation: profile

**Code:** `domain/use_case/auth/delete_account_use_case.dart`; feature `presentation/profile`.
Behavior: [behavior/profile.md](../behavior/profile.md).

## Presentation

- `ProfileBloc` reads the current user from `WatchAuthStateUseCase`. It does not
  import `presentation/auth`. Sign-out and account deletion switch the page to the guest view
  without navigation.
- Sign out calls `SignOutUseCase`; delete account calls `DeleteAccountUseCase`. Both
  are a `ProfileAction` with one `droppable` handler, so no account action starts while one
  runs (PRF-9). The delete event leaves the password out of `toString()` (OBS-7).

## Use case: `domain/use_case/auth/delete_account_use_case.dart`

Encodes a business rule (deletion only after a fresh password check):

1. `AuthRepository.reauthenticate(password)`. Firebase requires a recent sign-in for
   deletion; re-authenticating first avoids the `requires-recent-login` error. If it fails,
   stop and return the failure.
2. `AuthRepository.deleteAccount()`. The user id is read before this step, because deletion
   ends the session.
3. `FavoriteRepository.clearForUser(uid)`. A failure is logged by the repository and does not
   fail the use case: the account is already gone. The orphaned box stays on the device and is
   not retried.

The rule for other user data stored on the device:
[architecture.md](../architecture.md), Cache or user data.

The use case also sends `account_deleted` (PRF-8) after step 2 succeeds.
