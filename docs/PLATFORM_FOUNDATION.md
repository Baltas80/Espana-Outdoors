# España Outdoor — Platform Foundation

## Status

Implemented on `feat/platform-foundation-2026` as the first production-foundation increment. This layer deliberately uses mature infrastructure and keeps provider details outside the domain.

## Provider policy

| Capability | Selected foundation | Role of España Outdoor code |
|---|---|---|
| Mobile/Web UI | Flutter | Product UX and domain orchestration |
| Android/iOS map engine | MapLibre | Adapter, style, offline catalog |
| Desktop map fallback | flutter_map | Same MapService contract |
| PMTiles | `pmtiles` Dart package | Offline catalog and lifecycle |
| Routing | Valhalla | Outdoor profiles, policy and fallback |
| GIS database | PostGIS | Domain schema and policies |
| Tile server | Martin | Configuration and source catalog |
| Identity | Keycloak/OIDC | AuthService adapter and roles |
| Billing | RevenueCat | Entitlements and plan policy |
| Weather | AEMET OpenData | Source adapter, freshness and provenance |
| Environment | MITECO/OGC | Source adapter and provenance |
| Official GIS | IGN/CNIG/OGC | Source adapter and provenance |
| Telemetry | OpenTelemetry/Sentry | Integration and privacy policy |
| Metrics | Prometheus/Grafana | Dashboards and SLOs |
| Events | NATS initially | Critical event contracts |

## Important platform constraint

The current Flutter MapLibre plugin supports Android, iOS and Web, but not Windows/macOS/Linux. Therefore the client keeps a provider-neutral `MapService` and uses `flutter_map` as the desktop-capable rendering path until a mature desktop MapLibre option is selected. This is intentional and avoids a premature platform-specific rewrite.

## Entitlements

The client contains a single entitlement catalog for Free, Premium and Professional. Store products must map to RevenueCat entitlements; UI features must consume entitlements rather than checking product IDs or prices.

## Safety boundary

The Risk Engine is deliberately deterministic and conservative. It cannot turn missing or stale evidence into an approval. Official emergency services always take precedence. Rescue Link remains a separately authorized, expiring workflow.

## Production rule

Development Compose is a reproducible local integration environment. Production must use pinned image digests, managed secrets, TLS, backups, database HA where required, network policies, observability and disaster recovery. `start-dev` Keycloak mode is not permitted in production.
