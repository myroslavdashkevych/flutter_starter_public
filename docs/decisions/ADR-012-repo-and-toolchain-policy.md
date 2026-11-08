# ADR-012: repository and toolchain policy

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

The starter is a template that must build from a fresh clone, run in CI and stay easy to
review and upgrade.

## Decision

1. **Generated code is not committed.** Files produced by `build_runner` and gen-l10n are in
   `.gitignore` and generated locally and in CI. Pull request diffs show only hand-written
   code, branches do not conflict in generated files such as the DI config, and CI builds from
   a clean checkout, so the generated code always matches its sources.
2. **`.fvmrc` tracks the `stable` channel**, not a fixed release, so the starter always uses
   the current stable Flutter.
3. **Firebase config files are committed**, so the template runs after cloning and CI works.
   They are not secrets; protection relies on Security Rules.
4. **CI actions are referenced by version tags** (`@v7`, `@v2`), not pinned to commit SHAs:
   pinning would need manual or Dependabot updates, which this template avoids.

## Alternatives considered

- Committing generated code: rejected for the reasons in 1.
- A fixed Flutter version: a project created from the template may pin one (`fvm use <version>`).
- Pinning actions to SHAs: rejected for the reason in 4.

## Consequences

- After a fresh clone, run `fvm dart run build_runner build` and `fvm flutter gen-l10n` before
  the app compiles.
- CI and fresh clones pick up a new stable release as soon as it ships, so a Flutter release
  can break the build without any change in the repository.
- The Firebase API keys are restricted in Google Cloud Console (Android: package name + SHA-1;
  iOS: bundle ID).
- A new project must run `tool/init_project.dart` and regenerate the Firebase configs;
  otherwise it would use the starter's Firebase projects.
- Details: [guides/setup.md](../guides/setup.md) (FVM, Committing Firebase configs, Generated
  code, CI).
