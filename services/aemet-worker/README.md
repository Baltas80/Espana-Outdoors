# AEMET Cloudflare Worker (experimental, not deployed)

This is an isolated prototype of the existing Go Source Gateway's AEMET daily municipality forecast route. It is deliberately not wired into production, DNS, routes, or any deployment workflow.

## Contract preserved

- `GET /v1/sources/aemet-weather?municipalityCode=03099`
- `GET /v1/sources/aemet-weather/health`
- Forecast response envelope has exactly the existing `data`, `provenance`, and `freshness` top-level fields.
- Normalized forecast items preserve `date`, `condition`, `min`, `max`, `precipitationProbability`, `precipitationMm`, `windSpeed`, and `windDirection`.
- The Go implementation remains authoritative until compatibility tests and a controlled review pass.

## Authentication and secrets

Every `/v1/*` request requires a signed RS256 bearer JWT. Validation checks the signature against the configured HTTPS JWKS endpoint, exact issuer, audience (string or array), expiry, optional not-before, reasonable issued-at, subject, and the exact role in `resource_access[OIDC_AUDIENCE].roles`. Realm roles and roles belonging to another client are not accepted. Missing or invalid tokens fail closed. `/healthz` is intentionally non-sensitive and does not expose key expiry or secret state.

Set `OIDC_ISSUER`, `OIDC_AUDIENCE`, `OIDC_REQUIRED_ROLE`, and `OIDC_JWKS_URL` to the values from the actual Keycloak realm. Placeholder values in `wrangler.toml` are not deployable configuration. AEMET key expiry must be configured as RFC3339 in `AEMET_API_KEY_EXPIRES_AT`. Add `AEMET_API_KEY` only through a Cloudflare secret binding, never a repository file or public client.

## Dates and upstream validation

The current contract has no client-supplied date parameter: it requests AEMET's current daily municipality forecast. Each upstream forecast date is validated as a real ISO date or valid timestamp and normalized to `YYYY-MM-DD`; invalid calendar dates are discarded. Data URLs returned by AEMET must use HTTPS and the exact `opendata.aemet.es` hostname. Redirects are rejected, response size is bounded, and provider errors are not returned verbatim.

## Free plan / cost guardrails

As of the docs checked on 2026-10-16, Workers Free lists 100,000 requests/day, 10 ms CPU/request, 128 MB memory, 50 subrequests/invocation and 100 Workers/account. These are account-wide quotas and can change. This prototype makes two AEMET subrequests per cache miss and currently does not implement durable shared caching or distributed rate limiting; do not expose it publicly until cache/rate-limit strategy and quotas are reviewed. No paid plan, KV, D1, R2, domain route, or deployment is configured here. `workers_dev = false` avoids publishing a workers.dev endpoint by default.

## Local checks

Use Node 22+:
```sh
npm ci
npm run check
npx wrangler deploy --dry-run
```
The dry run only builds the bundle; do not run `wrangler deploy` or `wrangler secret put` for this task. Tests use mocked JWKS and AEMET responses and never require real credentials.

## Known gaps before production

- A durable shared cache and distributed per-subject rate limit are not implemented.
- OIDC provider/JWKS rotation and outage behavior needs integration testing against the actual Keycloak realm.
- Contract tests must compare representative Go and Worker outputs, including wind direction normalization; Worker intentionally returns null wind direction until parity is implemented.
- Confirm actual API-key expiry, AEMET quotas, Cloudflare account plan, and exact deployed OIDC values before any deployment.
- No production deployment or external endpoint verification has been performed.
