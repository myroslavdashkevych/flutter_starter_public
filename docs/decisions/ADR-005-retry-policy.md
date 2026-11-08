# ADR-005: request retry policy

- Status: Accepted
- Date: 2026-11-07 (recorded; the decision predates this record)

## Context

Most transient failures (a network switch, a short server overload) last a fraction of a
second. Retrying them hides short glitches, but a retry can repeat a side effect, and long waits feel worse
than an honest error.

## Decision

`RetryInterceptor` on both Dio clients, last in the chain:

- Retries only GET and HEAD: a POST whose response was lost may already have been applied, and
  repeating it could apply it twice.
- Retries a connection error and HTTP 408, 429, 502, 503 and 504. Not timeouts (the user has
  already waited for them), not 500 (usually a server bug), not a cancelled request.
- At most 2 retries with full-jitter exponential backoff (up to 0.5 s, then up to 1 s).
  - Most transient failures last a fraction of a second, so a quick first retry catches them;
    a failure that outlives it is likely longer, so the second retry waits twice as long. Up
    to 1.5 s in total still feels like a normal load; after that an error with a retry button
    is more honest than a longer loader.
  - The delay is random (jitter): after an outage, fixed delays make every client retry at the
    same moment, and the burst can take the recovering server down again.
- A `Retry-After` in seconds is waited for when it is at most 3 s; a longer one or an HTTP date
  means no retry, so the error and its retry button appear at once.
- The retry goes through the same `Dio`, so it gets a fresh token from `AuthInterceptor` and is
  logged. In `backendDio` it comes after `AuthInterceptor`, so a 401 is refreshed first.

`AuthInterceptor` retries a refreshed 401 through a separate `Dio` without itself: a failed
retry on the same client would wait in the error queue held by `onError`.

## Alternatives considered

None recorded. The numbers are a UX judgment, not a standard.

## Consequences

- Tune `maxRetries`, `baseDelay` and `maxRetryAfter` per app.
- Offline, cached data or the error appears after the retries, up to 1.5 s later.
- Details: [spec/architecture.md](../spec/architecture.md), Networking.
