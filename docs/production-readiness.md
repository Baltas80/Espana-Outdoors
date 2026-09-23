# Production readiness

## Current product boundary

España Outdoor uses mature third-party infrastructure for the commodity layers and keeps proprietary code focused on product differentiation and safety-critical orchestration.

### Mature components

- Flutter/Dart: multiplatform application shell.
- flutter_map / MapLibre ecosystem: map rendering.
- PMTiles/MBTiles: offline map distribution.
- Valhalla: outdoor routing, map matching and turn-by-turn data.
- Hive CE: local route/offline metadata persistence.
- background_downloader: resumable native downloads.
- RevenueCat: subscription/billing entitlements.
- OpenID Connect: standards-based identity; production provider target is Keycloak.
- Sentry: crash/error telemetry.
- GitHub Actions + Dependabot + Trivy + Gitleaks: CI and supply-chain baseline.

Valhalla 3.9.0 is the current pinned routing release in the repository. Its REST API exposes routing, status and related services and the project is MIT licensed. The application must use an internally operated/contracted Valhalla deployment rather than a public routing endpoint for production traffic.

## Runtime configuration

Secrets and provider endpoints are injected at build/deployment time. They must never be committed.

| Variable | Purpose | Required in production |
|---|---|---|
| `VALHALLA_BASE_URL` | Routing endpoint | Yes |
| `OFFLINE_CATALOG_URL` | Published offline-region catalogue | Yes |
| `AEMET_API_KEY` | AEMET OpenData credential | Backend only; never ship to the client |
| `SENTRY_DSN` | Error/crash telemetry | Yes |
| `APP_ENV` | Environment label | Yes |
| `REVENUECAT_API_KEY` | Public RevenueCat SDK key | Yes for store billing |
| `OIDC_ISSUER` | Keycloak/OIDC issuer | Yes for authenticated production |
| `OIDC_CLIENT_ID` | Public OIDC client identifier | Yes |

## Billing

The application exposes `OutdoorPlan.free`, `premium` and `professional`. UI and feature code consume `OutdoorEntitlement`; they must not branch on RevenueCat product IDs.

RevenueCat entitlements should be configured as:

- `premium`
- `professional`

The Professional entitlement takes precedence if both are active. Store products, prices and promotional offers remain configuration in RevenueCat/App Store/Google Play rather than hard-coded application logic.

## Identity

The client target is OpenID Connect Authorization Code + PKCE against Keycloak. Native and browser authentication must use platform/system browser flows. Passwords are never collected by the application itself when OIDC is enabled.

## Safety data policy

The risk engine is deterministic and auditable. A risk score is not a safety guarantee. Every dynamic signal must carry source, freshness and expiry where applicable. If required data is missing, confidence remains below 1 and the UI must communicate the limitation.

Emergency features must not depend on analytics, billing or remote map availability.

## Release gates

A production release is blocked unless:

1. `flutter analyze` passes.
2. Unit/widget tests pass.
3. Routing/offline focused tests pass.
4. Gitleaks reports no secrets.
5. Trivy has no unfixed HIGH/CRITICAL finding accepted without an explicit security decision.
6. Dependency licences have been reviewed.
7. Dynamic sources have documented attribution, freshness and fallback behaviour.
8. No production endpoint or secret is hard-coded in the client.
9. SOS/112 flows have been tested on supported mobile hardware.
10. Offline navigation has been tested with connectivity disabled.

## Known external prerequisites

The repository can implement and validate client contracts without inventing infrastructure credentials. Production still requires deployment of the backend/source gateway, Valhalla regional tiles, offline catalogue, Keycloak realm/client configuration, RevenueCat store configuration and Sentry project. Those are environment/service configuration tasks, not values that should be fabricated in Git.
