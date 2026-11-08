# Profile

Guest or account view, sign-out and account deletion. Implementation:
[areas/profile.md](../areas/profile.md).

## Requirements

- **PRF-1** While the auth state is unknown, the profile page shows an empty body, so the
  sign-in button does not flash.
  - GIVEN the auth state is not known yet WHEN the Profile tab opens THEN the body is empty
- **PRF-2** A guest sees a short explanation and **Sign in**, which opens `/sign-in`.
  - GIVEN a guest WHEN the Profile tab opens THEN the explanation and **Sign in** are shown
  - WHEN the guest taps **Sign in** THEN `/sign-in` opens
- **PRF-3** A signed-in user sees their email and the entries **Favorites**, **Sign out** and
  **Delete account**. **Favorites** opens `/profile/favorites`.
  - GIVEN a signed-in user WHEN the Profile tab opens THEN the email and the three entries are shown
  - WHEN the user taps **Favorites** THEN `/profile/favorites` opens
- **PRF-4** **Sign out** asks for confirmation, then signs the user out. The page switches to the
  guest view without navigation.
  - WHEN the user taps **Sign out** and confirms THEN the user is signed out and the guest view
    is shown on the same page
  - WHEN the user cancels THEN nothing changes
- **PRF-5** **Delete account** shows a warning that the action is permanent, then asks for the
  password, and deletes the account only after the password is checked again.
  - WHEN the user taps **Delete account** THEN a warning dialog explains that the action is permanent
  - WHEN the user confirms and enters the correct password THEN the account is deleted and the
    guest view is shown without navigation
- **PRF-6** Deleting the account also deletes the user's favorites stored on the device. A
  failure to delete them does not fail the account deletion.
  - WHEN the account is deleted THEN the user's favorites are removed from the device
  - WHEN removing the favorites fails THEN the account deletion still counts as successful
- **PRF-7** A failed deletion shows a localized message for a wrong password, a network
  failure or too many requests, and the user stays signed in.
  - WHEN the user enters a wrong password THEN the wrong password message is shown and the user
    stays signed in
  - WHEN deletion fails because of the network or too many requests THEN the matching message
    is shown and the user stays signed in
- **PRF-8** `account_deleted` is sent when the account has been deleted.
  - WHEN deletion succeeds THEN `account_deleted` is sent
  - WHEN deletion fails THEN no event is sent

## Scope

The starter has no backend, so deletion removes the Firebase Auth account and the local
favorites only. A real project with a backend must also delete server-side user data (a
backend endpoint or a Cloud Function on user deletion). Apple App Store and Google Play
require in-app account deletion for apps that allow sign-up.

## Screens

### SCR-7 Profile

- Route: `/profile` (second tab).
- States: unknown (PRF-1); guest (PRF-2); signed in (PRF-3); sign-out confirmation dialog
  (PRF-4); delete account warning and password dialogs (PRF-5, PRF-7).
- Design: pending

## Implementation notes

- PRF-5: Firebase requires a recent sign-in for deletion; checking the password first avoids
  the `requires-recent-login` error.

Retired: none
