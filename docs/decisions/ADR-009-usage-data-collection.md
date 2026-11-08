# ADR-009: usage data collection = flavor rule AND user setting

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

Analytics and crash reporting must respect the user's "Share usage data" setting, while the
`dev` flavor must always report so that reporting can be verified.

## Decision

- Effective collection = `Flavor.collectsUsageData` AND the "Share usage data" setting; the
  flavor rule wins. Always on in the `dev` flavor: the dev Firebase project exists for this,
  and it lets the agent verify reporting with debug builds. In `prod`, only in non-debug builds.
- Collection is on by default and the user can turn it off (opt-out).
- Crashlytics applies `false` only from the next run, so `FirebaseCrashReportingService` drops
  errors itself while collection is off and deletes the reports stored on the device.

## Alternatives considered

- Opt-in (collection off until the user agrees): available as an optional switch in a project
  ([guides/store-release.md](../guides/store-release.md), Switching to opt-in). It lowers the
  accuracy of crash-free and event metrics; whether a project needs it depends on its legal
  requirements in each market.

## Consequences

- The native SDKs collect by default until the first call on the very first launch.
- Mechanism: [spec/architecture.md](../spec/architecture.md), Logging and errors; behavior:
  SET-7 in [spec/features/settings.md](../spec/features/settings.md).
