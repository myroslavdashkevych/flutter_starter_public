# Area: network

**Areas:** `data/_shared/network`, `app/di/network_module.dart`. Behavior: [features/items.md](../features/items.md)
(ITM-7, ITM-8), the only feature that uses it.

How the shared Dio clients work. The rules they follow:
[architecture.md](../architecture.md), Networking. Why: [ADR-004](../../decisions/ADR-004-dio-retrofit.md),
[ADR-005](../../decisions/ADR-005-retry-policy.md).

## Clients

- `dio_factory.dart` creates `publicDio` and `backendDio`.
- The logging rule is applied by `TalkerDioLogger` (`createDioLogger` in `dio_factory.dart`),
  with `logBodies` set per flavor in `app/di/network_module.dart`.
- The starter has no own backend: `backendDio` is registered and fully covered by unit tests
  with a mocked adapter, but not used by a feature yet.

## AuthInterceptor

`QueuedInterceptor`, `backendDio` only:

1. `onRequest`: adds `Authorization: Bearer <token>` from `TokenProvider`.
2. `onError` applies the 401 rule: it forces a refresh through `TokenProvider` and, on a
   second 401, calls `TokenProvider.onUnauthorized()`.

- The retry goes through a separate `Dio` without this interceptor (ADR-005).
- A queued 401 whose token has already been replaced retries with the current token instead
  of refreshing again.

## RetryInterceptor

Both clients, last in the chain:

- For GET and HEAD, retries a connection error and HTTP 408, 429, 502, 503 and 504; not
  timeouts, not 500, not a cancelled request.
- At most 2 retries with full-jitter exponential backoff (up to 0.5 s, then up to 1 s). A
  `Retry-After` in seconds is waited for when it is at most 3 s; a longer one or an HTTP date
  means no retry, so the error and its retry button appear at once.
- The numbers are a UX judgment, not a standard: tune `maxRetries`, `baseDelay` and
  `maxRetryAfter` per app.
- The retry goes through the same `Dio`, so it gets a fresh token from `AuthInterceptor` and
  is logged. In `backendDio` it comes after `AuthInterceptor`, so a 401 is refreshed first.
- While a request is retried, a screen keeps its loading state: offline, the cached data or
  the error appears after the retries, up to 1.5 s later.
