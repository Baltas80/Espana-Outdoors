# ADR-0002 — Gateway for live official data and secrets

**Status:** Accepted for MVP-to-production transition.

## Context

España Outdoor consumes official live sources such as AEMET and, later, civil-protection, fire, environmental and regional feeds. Some providers require credentials, impose quotas, rotate keys or expose provider-specific response formats.

A mobile/web client is not a safe place for long-lived provider credentials: application binaries can be inspected, keys can be extracted and provider quotas would be shared directly by all clients.

AEMET currently documents that API keys without an expiration date will stop working on 15 October 2026 and that newly requested keys have a three-month validity. Production therefore needs controlled secret rotation and provider-side rate limiting from the start.

## Decision

Introduce a server-side **Live Data Gateway** between the Flutter clients and credentialed/fragile external sources.

```text
Flutter clients
      |
      | authenticated product API
      v
Live Data Gateway
  |        |        |
AEMET    Alerts   Regional adapters
  |        |        |
  +--- cache / retry / backoff / provenance ---+
                         |
                  normalized domain records
```

The gateway is responsible for:

- keeping provider credentials out of client binaries;
- provider-specific authentication and secret rotation;
- rate limiting and quota management;
- timeout, retry and exponential backoff policies;
- caching and stale-while-revalidate where safe;
- schema validation before data enters the product domain;
- provenance, attribution, source timestamps and validity windows;
- explicit stale/error states when a provider fails;
- provider failover where a legally compatible alternative exists;
- audit-safe operational logs without sensitive location leakage.

The Flutter layer consumes normalized contracts and must not depend on AEMET-specific authentication details.

## Security requirements

1. No AEMET or other provider API key is committed to Git or bundled into release artifacts.
2. Secrets are injected through the deployment secret manager/environment at runtime.
3. Secrets are rotated before provider expiry, with alerting on upcoming expiry.
4. Client authentication and provider authentication are separate credentials.
5. Gateway logs must redact authorization headers, API keys, personal data and exact emergency coordinates.
6. Rate limits apply per authenticated client identity and per provider quota.
7. Emergency and exact-location data must not be forwarded to unrelated data providers.

## Failure semantics

A provider failure is never represented as fresh data. The gateway returns an explicit status such as `current`, `aging`, `stale` or `unavailable`, together with the last successful retrieval timestamp when applicable.

Official warnings retain their official provenance. España Outdoor derived recommendations remain a separate semantic layer and must never be presented as official warnings.

## Consequences

### Positive

- Provider credentials are protected from client extraction.
- Provider changes do not require a client release.
- Caching and quotas are centrally controllable.
- Multiple official and regional adapters can share the same normalized contracts.
- Observability and incident response become practical before public launch.

### Negative

- Adds backend infrastructure and operating cost.
- Requires deployment, monitoring and API authentication.
- The product is no longer purely client-side.

## Production gate

Before public release, the Flutter application must use the gateway for credentialed live providers. The existing AEMET adapter is therefore treated as provider-specific integration code and must not receive a production secret inside the mobile/web application bundle.

## Sources

- AEMET OpenData: https://www.aemet.es/es/datos_abiertos/AEMET_OpenData
- AEMET API-key expiry notice: https://opendata.aemet.es/centrodedescargas/novedades
