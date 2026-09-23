# Live Data Gateway

First-party gateway for official live data. Provider credentials stay on the server; mobile clients receive normalized records with explicit provenance and freshness.

## Current provider

- AEMET OpenData municipality daily forecasts (`aemet-weather`).
- AEMET API key is read only from `AEMET_API_KEY` at runtime.
- `AEMET_API_KEY_EXPIRES_AT` is mandatory and is checked at startup.
- The gateway uses OIDC bearer authentication and per-subject rate limiting.
- AEMET failures use bounded retry/backoff and stale-cache fallback.

## Runtime configuration

| Variable | Required | Purpose |
|---|---:|---|
| `OIDC_ISSUER` | yes | OIDC issuer used to validate product access tokens |
| `OIDC_AUDIENCE` | yes | Expected access-token audience |
| `AEMET_API_KEY` | yes | AEMET provider credential, runtime only |
| `AEMET_API_KEY_EXPIRES_AT` | yes | RFC3339 expiry used for startup/health monitoring |
| `AEMET_BASE_URL` | no | Defaults to `https://opendata.aemet.es/opendata/api` |
| `PORT` | no | Defaults to `8080` |
| `CACHE_FRESH_TTL` | no | Defaults to `10m` |
| `CACHE_AGING_TTL` | no | Defaults to `10m` |
| `CACHE_STALE_TTL` | no | Defaults to `40m` |
| `RATE_LIMIT_RPS` | no | Defaults to `2` |
| `RATE_LIMIT_BURST` | no | Defaults to `10` |
| `ALLOW_HTTP_DEV` | no | Local-only development escape hatch; must be false in production |

## API

- `GET /healthz` — gateway process health plus AEMET key-expiry state.
- `GET /v1/sources/aemet-weather/health` — normalized provider health/freshness.
- `GET /v1/sources/aemet-weather?municipalityCode=03099` — normalized forecast envelope.

All `/v1/*` endpoints require a valid OIDC bearer token.

The client must never send the AEMET API key. The gateway attaches it only to the AEMET provider request.

## Freshness semantics

`current` means the gateway cache is within `CACHE_FRESH_TTL`.

`aging` means the fresh window has elapsed but the cached response is still within the next `CACHE_AGING_TTL`.

`stale` means a cached response is older than the aging window but still inside `CACHE_STALE_TTL`; it is returned only when a provider refresh fails.

`unavailable` means there is no usable cached response.

## Deployment

Use HTTPS at the edge, inject secrets through the platform secret manager, and expose `/healthz` to the infrastructure monitor. Do not publish AEMET credentials, access tokens or exact emergency locations in logs.
