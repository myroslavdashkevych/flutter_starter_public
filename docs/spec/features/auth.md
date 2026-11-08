# Auth

Email and password authentication with Firebase Auth. Optional: see NAV-4.
Implementation: [areas/auth.md](../areas/auth.md).

## Requirements

- **AUTH-1** The email field accepts a non-empty value in a basic email format.
  - WHEN the user submits an empty email or one without a basic email format THEN a validation
    message is shown and no request is sent
- **AUTH-2** The password must have at least 6 characters (the Firebase default policy).
  - WHEN the user submits a password shorter than 6 characters THEN a validation message is
    shown and no request is sent
- **AUTH-3** On sign-up, the password confirmation must match the password.
  - WHEN the confirmation differs from the password THEN a validation message is shown and no
    request is sent
- **AUTH-4** While a request runs, the page shows a loading state and the submit button is disabled.
  - WHEN the user submits a valid form THEN a loading state is shown and submit is disabled
    until the request ends
- **AUTH-5** Each failure reason is shown as its own localized message: invalid credentials,
  email already in use, weak password, invalid email, user disabled, too many requests,
  requires recent login, network, unknown.
  - WHEN a request fails THEN the page shows the localized message for that reason
- **AUTH-6** A wrong email and a wrong password give the same message (invalid credentials),
  because email enumeration protection is on (the default for new Firebase projects).
  - WHEN the user signs in with an unknown email THEN the invalid credentials message is shown
  - WHEN the user signs in with a known email and a wrong password THEN the same message is shown
- **AUTH-7** Password reset reports success whether or not the address has an account.
  - WHEN the user requests a reset for an address without an account THEN "check your email"
    is shown, as for an existing account
- **AUTH-8** Analytics events: `login` after a successful sign-in, `sign_up` after a successful
  sign-up (standard Firebase event names), `password_reset_requested` after a successful reset
  request.
  - WHEN sign-in succeeds THEN `login` is sent
  - WHEN sign-up succeeds THEN `sign_up` is sent
  - WHEN a password reset request succeeds THEN `password_reset_requested` is sent
  - WHEN any of these requests fails THEN no event is sent

After a successful sign-in or sign-up the user lands on `/profile` (NAV-6).

## Screens

### SCR-1 Sign in

- Route: `/sign-in`, pushed over the shell from the Profile tab (also from the favorites page, FAV-6).
- States: form (AUTH-1, AUTH-2), loading (AUTH-4), error (AUTH-5, AUTH-6). Links to sign-up and
  password reset.
- Design: pending

### SCR-2 Sign up

- Route: `/sign-up`, pushed from `/sign-in`.
- States: form (AUTH-1, AUTH-2, AUTH-3), loading (AUTH-4), error (AUTH-5).
- Design: pending

### SCR-3 Reset password

- Route: `/reset-password`, pushed from `/sign-in`.
- States: form (AUTH-1), loading (AUTH-4), success "check your email" (AUTH-7), error (AUTH-5).
- Design: pending

## Implementation notes

- AUTH-7: the Firebase `user-not-found` error is treated as success.

Retired: none
