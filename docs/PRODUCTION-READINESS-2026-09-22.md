# España Outdoor — Production Readiness Review

**Review date:** 2026-09-22  
**Baseline:** `master` at commit `67db1d008d5791103006cbcd8a4980e8bbaf3b08`  
**Working branch:** `cto/mvp-hardening-2026-09-22`

## Current state

The repository is a Flutter application with a layered architecture, Riverpod state management, `flutter_map`, GPS/location, GPX import/export, local route persistence, offline capability contracts, AEMET adapter foundations, safety/trusted contacts, pet and wildlife foundations, and CI/security workflows.

The current codebase is **not yet production-ready**. The most important remaining gaps are provider-backed offline map packages, official alert ingestion, secure weather runtime configuration, routing/elevation, backend synchronization, hardened SOS/Rescue Link, platform validation, accessibility/E2E/performance testing, and release signing.

## Decisions confirmed by current external research

### OpenStreetMap tiles

The public OSM tile service explicitly prohibits bulk downloading and offline prefetching and provides no SLA. España Outdoor must therefore not implement offline downloads against `tile.openstreetmap.org`. Use self-hosted or explicitly licensed offline-capable map distribution instead. Attribution remains mandatory. See the official policy: https://operations.osmfoundation.org/policies/tiles/

### AEMET

AEMET OpenData provides a REST API for reusable meteorological data. AEMET currently states that API keys issued without an expiration date stop working on **2026-10-15**, while newly requested keys have a three-month validity. Production infrastructure must therefore own key rotation and must not ship a privileged AEMET key inside the Flutter application. See AEMET OpenData and current notices: https://www.aemet.es/es/datos_abiertos/AEMET_OpenData and https://opendata.aemet.es/centrodedescargas/novedades

### MapLibre

MapLibre's Flutter ecosystem is materially more mature than the repository's original research snapshot. Current MapLibre reporting documents offline-region work, pause/resume and progress support, and Flutter Web/WASM improvements. This justifies a measured Android/iOS/Web evaluation against `flutter_map` before committing the production renderer, while retaining the provider-neutral abstraction and desktop fallback. See: https://maplibre.org/news/2026-05-02-maplibre-newsletter-april-2026/

## Immediate release blockers

1. No production offline tile source/provider has been contracted or self-hosted.
2. AEMET credentials are not yet mediated by a backend/runtime secret service.
3. Official alert/CAP ingestion is not implemented end-to-end.
4. Route readiness now has a deterministic domain evaluator, but live weather/alert/route-condition factors are not yet connected.
5. SOS/Rescue Link require real-device and backend session-expiry validation.
6. No complete Android/iOS/Web/Windows/macOS/Linux release matrix has passed.
7. No signed release artifacts or store deployment pipeline is established.

## Next execution order

1. Implement official alert normalization adapters and freshness safeguards.
2. Introduce secure backend gateway contracts for AEMET and other privileged feeds.
3. Implement resumable offline-region storage/download state without coupling the UI to a tile vendor.
4. Benchmark MapLibre versus `flutter_map` on mobile/web and preserve desktop compatibility.
5. Add routing/elevation behind provider interfaces after license/cost/coverage review.
6. Harden SOS with device state, expiry and real-device E2E tests.
7. Add integration/E2E/accessibility/performance CI gates.
8. Produce signed beta builds for each supported platform.

## Safety rule

No live feed, emergency capability, or safety recommendation may be represented as operational until its source, freshness, failure mode, privacy treatment and test coverage are verified.
