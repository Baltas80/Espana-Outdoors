# Live Data Gateway skeleton

This directory defines the server-side boundary for provider credentials, normalization, caching and provenance. It is intentionally framework-neutral until deployment requirements are selected.

## Production responsibilities

- Authenticate client requests.
- Enforce authorization and per-user/provider rate limits.
- Keep AEMET and other provider credentials server-side.
- Normalize external responses into versioned domain contracts.
- Attach provenance and freshness metadata.
- Cache according to dataset-specific TTL.
- Apply bounded retries and circuit breaking.
- Emit metrics/traces without leaking secrets or precise emergency locations.
- Expose health/readiness checks for provider dependencies.

## Initial modules

```text
backend/
  contracts/       normalized API/domain contracts
  providers/       provider adapters
  cache/           TTL and stale-state policy
  security/        auth, rate limits, secret boundary
  observability/   metrics, traces, structured logs
```

No provider API key belongs in this repository. Runtime configuration must be supplied by the deployment environment or a managed secret store.
