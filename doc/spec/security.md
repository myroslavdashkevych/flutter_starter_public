# Security

Every security rule of the app and the repository lives here. A rule belongs here when
breaking it leaks credentials, tokens or personal data, or weakens the app against an
attacker. A protection the starter does not use is recorded as a decision with its reason and
the trigger that reopens it; a rule not implemented yet says so and names the change that
implements it.

**Here:** the security rules of the app and the repository; the decisions on protections the
starter does not use, each with its reason and trigger.

**Not here:** the mechanics these rules constrain ([architecture.md](architecture.md):
Networking, Logging and errors, Local storage); procedures
([guide/setup.md](../guide/setup.md), Security checklist and CI;
[guide/store-release.md](../guide/store-release.md)); rules for agents (`CLAUDE.md`).

## Secrets and the repository

- No real secrets are ever committed: git history keeps them forever. A pattern is added to
  `.gitignore` before a new kind of secret enters the project.
- `config/*.json` holds non-secret values only, because they can be extracted from the
  binary.
- The starter ships without Firebase config files
  ([guide/setup.md](../guide/setup.md), Committing Firebase configs). A project created
  from it commits them: they are not secrets, they only identify the Firebase projects. Their API keys are restricted in Google Cloud Console to Firebase-related APIs
  and to the app (Android: package name + SHA-1; iOS: bundle ID)
  ([guide/setup.md](../guide/setup.md), Restrict the API keys). This limits casual misuse
  of a copied key but is easy to bypass, so it protects no data: once a project adds a
  Firebase database or storage, its Security Rules do.
- The release signing key and its passwords live only in `android/key.properties`, which is
  never committed.

## Tokens

- The Firebase ID token goes only to the app's own backend, through `backendDio`. It is
  **never** attached to a third-party API: `publicDio` carries no auth header.

## Logs and reports

- Network logs never contain the `Authorization` header and, in `prod`, no bodies.
- An event never prints a secret in `toString()`, because events are logged outside `prod`
  (OBS-7).
- `TalkerBlocObserver` logs only errors in `prod` (OBS-6), because states hold user data.

## Personal data

What may reach crash reports and analytics:

- the Firebase UID in crash reports (OBS-2);
- route names that carry no ids (OBS-3);
- event parameters that name no person. The search term (CHR-17) is accepted as is: the
  starter sets no Analytics User-ID, so it is not linked to the account.

Never: an email address, a password, a token. Logs outside `prod` may hold user data from
states and bodies, never a password (OBS-7) or the `Authorization` header.

New data that reaches crash reports or analytics updates the store data forms
([guide/store-release.md](../guide/store-release.md), Declare the data).

## Usage data consent

- Usage data is collected only when the flavor allows it and the "Share usage data" setting is
  on (SET-7).

## Local storage

- No secure storage: Firebase Auth persists and refreshes the session itself.
- Hive stores no secrets and no sensitive personal data, so it is not encrypted: the character
  cache holds public API data and favorites hold snapshots of it. Trigger: when secrets or
  sensitive personal data must be stored, they go to the platform keystore through a new
  package, in a change of their own.

## Release hardening

- **Obfuscation:** store builds are built with `--obfuscate --split-debug-info`, and the
  symbols are uploaded to Crashlytics
  ([guide/store-release.md](../guide/store-release.md), Crashlytics symbols).
- **Firebase App Check:** not used. The starter has no own backend and no Firestore, Storage
  or Functions, which App Check protects. Trigger: a project adds one of them.
- **Certificate pinning:** not used. The starter calls a public API and Firebase, and pinning
  breaks the app when a certificate rotates. Trigger: a project adds its own backend.

## Dependencies and CI

- `permissions: contents: read`: the run's token can only read the repository.
- `persist-credentials: false` on checkout: the token is not left in `.git/config`, so later
  steps (third-party actions, package build hooks, code generators) cannot read it. The
  workflow never pushes, so it needs no stored token.
- Actions are pinned to full commit SHAs, with the version in a comment
  (`actions/checkout@<sha> # v7.0.1`): a moved tag cannot run changed code. Dependabot
  updates the SHA and the comment together.
- Dependencies (`pub`) and actions (`github-actions`) are updated by Dependabot: monthly
  version update pull requests into `develop`
  ([guide/setup.md](../guide/setup.md), Dependabot). Dependabot alerts report known
  vulnerabilities. Automatic security update pull requests are off, because GitHub always
  opens them against the default branch (`main`), which receives only merges from
  `develop`; an alert is fixed by the next version update or by a change of its own.
