# España Outdoor — Production closeout

This document is the release-control checklist for the final parallel workstream.

## A. Android physical QA

**Artifact selection is part of the release gate.** The CI job deliberately builds with `APP_ENV=ci` and does not inject production map endpoints. Its artifact is named `android-ci-validation`; it is for build/test evidence only and must not be used as the production-ready app on a phone.

Use:
- `android-staging-apk` from a successful **Android staging** run for pre-production app and map smoke tests. A passing emulator smoke is not proof that production services are deployed.
- `android-release-candidate` from the **Release candidate** workflow for production-profile validation. That workflow must pass its real HTTPS endpoint gates before the APK/AAB is considered a candidate.

Install the exact selected APK on a physical Android device and record:

- device model and Android version;
- build identifier / commit SHA;
- clean install and cold start;
- runtime permissions;
- GPS acquisition and accuracy;
- map rendering;
- route planning;
- navigation guidance and reroute;
- offline region download and airplane-mode rendering;
- SOS preparation and 112 handoff without routine live calls;
- Rescue Link create/copy/revoke;
- background location / screen-off;
- battery and thermal sanity.

Known manual observation: the map screen reports `No hay PMTiles configurado: falta MAP_PMTILES_URL y OFFLINE_CATALOG_URL` when the CI-profile APK is installed without a verified local archive. Do not suppress this error. Confirm the artifact profile first; production readiness still depends on verifying the real PMTiles/catalog endpoints and testing the production candidate on-device.

## B. iOS physical QA

CI already verifies the native location configuration and produces a no-code-sign release build. Physical validation still requires Apple device/test distribution and the same core route, map, offline, navigation, SOS and Rescue Link flows.

## C. External production infrastructure

The application boundary is already provider-neutral. Do not hard-code credentials or silently substitute public demo endpoints.

Required production services:

1. **PMTiles / map provider** — approved commercial or self-hosted source with explicit redistribution/prefetch rights.
2. **Valhalla** — dedicated production instance with Spain routing tiles and HTTPS.
3. **Live Data Gateway** — HTTPS endpoint with real AEMET credentials, OIDC and monitoring.
4. **Rescue Link** — HTTPS service, Keycloak/OIDC realm, PostgreSQL, managed secret material, backups and monitoring.

All four must have health checks and an application-level smoke test before release.

## D. Visual pack

Current repository assets include the LAND-01, LAND-02 and LAND-03 landscape assets plus the page background system. LAND assets are visual content only; UI controls never belong inside the images.

The Home hero now consumes the repository LAND-01 asset. The final BG-01 hero (person + dog on a Spanish trail) remains a replacement asset requirement if it has not yet been committed as a real image file.

Continue with LAND-04 and the flora/fauna pack without changing the locked UI structure.

## E. Navigation E2E

Release evidence must cover:

`GPS -> route request -> Valhalla -> route geometry -> guidance -> off-route detection -> reroute -> arrival`

The unit-level navigation guidance and Valhalla adapter tests are not a substitute for this physical E2E run.

## F. Final QA

No release candidate is green until Android and iOS evidence is attached to the physical QA gate and all critical failures have a reproducible resolution.

## G. Stores

Only after A-F:

- Android signed AAB;
- Play Console release track and policy/privacy material;
- iOS signed archive;
- App Store Connect / TestFlight;
- final screenshots and metadata;
- production monitoring and rollback plan.

## Runtime configuration

Production values are injected at build/deployment time. Example:

```text
--dart-define=APP_ENV=production
--dart-define=MAP_PMTILES_URL=https://<approved-endpoint>/spain.pmtiles
--dart-define=VALHALLA_BASE_URL=https://<routing-domain>/
--dart-define=SOURCE_GATEWAY_BASE_URL=https://<gateway-domain>/
--dart-define=RESCUE_LINK_BASE_URL=https://<rescue-domain>/
```

Do not commit actual credentials, private API keys, or production URLs until the provider and ownership decision has been made. A placeholder is intentionally not treated as a working production configuration.
