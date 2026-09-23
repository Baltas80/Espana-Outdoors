# Production readiness

## Current product boundary

España Outdoor uses mature third-party infrastructure for commodity layers and keeps proprietary code focused on product differentiation and safety-critical orchestration.

### Mature components

- Flutter/Dart: mobile application shell.
- MapLibre ecosystem: map rendering.
- PMTiles/MBTiles: offline map distribution.
- Valhalla: outdoor routing, map matching and turn-by-turn data.
- Hive CE: local route/offline metadata and crash-recoverable active-route segments during MVP.
- background_downloader: resumable native downloads.
- RevenueCat: subscription/billing entitlements.
- OpenID Connect: standards-based identity; production provider target is Keycloak.
- Sentry: crash/error telemetry.
- GitHub Actions + Dependabot + Trivy + Gitleaks: CI and supply-chain baseline.
- Rescue Link gateway: first-party HTTPS API boundary for server-authoritative expiry, revocation and role-based visibility.
- SHA-256 verification for offline packages when the catalog provides a checksum.

Valhalla 3.9.0 is the current pinned routing release in the repository. The application must use an internally operated or contracted Valhalla deployment for production traffic.

## Runtime configuration

| Variable | Purpose | Required in production |
|---|---|---|
| VALHALLA_BASE_URL | Routing endpoint | Yes |
| OFFLINE_CATALOG_URL | Published offline-region catalogue | Yes |
| SOURCE_GATEWAY_BASE_URL | First-party normalized official-data gateway | Yes |
| RESCUE_LINK_BASE_URL | First-party Rescue Link API | Yes |
| SENTRY_DSN | Error/crash telemetry | Yes |
| APP_ENV | Environment label | Yes |
| MAP_TILE_URL | Contracted or owned online map provider | Yes for raster MVP; replace with vector/PMTiles where deployed |
| MAP_ATTRIBUTION | Required map attribution | Yes when provider requires it |
| REVENUECAT_API_KEY | Public RevenueCat SDK key | Yes for store billing |
| OIDC_ISSUER | Keycloak/OIDC issuer | Yes |
| OIDC_CLIENT_ID | Public OIDC client identifier | Yes |
| OIDC_REDIRECT_URI | Registered OIDC callback | Yes |

## Safety data policy

The risk engine is deterministic and auditable. A risk score is not a safety guarantee. Every dynamic signal must carry source, freshness and expiry where applicable.

Emergency features must not depend on analytics, billing or remote map availability.

## Release gates

A production release is blocked unless:

1. flutter analyze passes.
2. Unit and widget tests pass.
3. Routing/offline focused tests pass.
4. Gitleaks reports no secrets.
5. Trivy has no unfixed HIGH/CRITICAL finding accepted without an explicit security decision.
6. Dependency licences have been reviewed.
7. Dynamic sources have documented attribution, freshness and fallback behaviour.
8. No production endpoint or secret is hard-coded in the client.
9. SOS/112 flows have been tested on supported mobile hardware.
10. Offline navigation has been tested with connectivity disabled.
11. Rescue Link backend expiry, revocation and role-based visibility have been integration-tested.

## Known external prerequisites

The repository can implement and validate client contracts without inventing infrastructure credentials. Production still requires deployment of the backend/source gateway, Valhalla regional tiles, offline catalogue, Keycloak realm/client configuration, RevenueCat store configuration, Sentry project and Rescue Link service.