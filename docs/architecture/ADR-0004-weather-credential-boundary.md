# ADR-0004 — Weather credential boundary and expiry

## Status
Accepted for the MVP integration boundary.

## Context
AEMET OpenData requires an API key. AEMET's current developer notices state that API keys issued without an expiry will stop being valid on 15 October 2026. The application therefore must not treat a weather credential as permanent configuration.

The mobile/web client is not a trusted secret store. A production deployment must prefer a server-side/gateway boundary for provider credentials. Local development may inject a short-lived test credential through the runtime environment, but no key belongs in source control, assets, generated configuration, or persistent client storage.

## Decision
1. `WeatherService` remains provider-neutral.
2. AEMET credentials are represented by `WeatherRuntimeConfig` and require an explicit expiry timestamp.
3. The AEMET adapter validates the credential immediately before a provider request.
4. Expired or missing credentials fail closed with a configuration error; cached weather may still be served according to the existing freshness policy.
5. Production credentials must be supplied through a trusted runtime/gateway boundary and rotated before expiry.
6. AEMET CAP/RSS warning feeds remain a separate alert-ingestion concern and must not be conflated with forecast credentials.

## Consequences
- Credential expiry becomes testable in CI rather than a calendar-only operational task.
- The app cannot silently continue using an expired AEMET key.
- A backend/gateway is the preferred production path for protecting provider credentials and applying rate limits, retries, caching and observability.
- Provider replacement remains possible without changing feature/UI contracts.

## Verification
The runtime configuration has deterministic unit coverage for valid, expired and missing credentials.

## Sources
- AEMET OpenData: https://www.aemet.es/es/datos_abiertos/AEMET_OpenData
- AEMET OpenData novedades: https://opendata.aemet.es/centrodedescargas/novedades
- AEMET weather warnings/RSS-CAP: https://www.aemet.es/es/rss_info/avisos/esp
