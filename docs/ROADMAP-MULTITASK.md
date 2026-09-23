# España Outdoor — Parallel Delivery Roadmap

The project is developed in parallel tracks so no major capability waits for another track to finish.

## Track A — Product & UX
- [x] premium responsive design system
- [x] home/discovery foundation
- [x] safety center foundation
- [x] pet mode foundation
- [x] wildlife guidance foundation
- [ ] route detail production UX
- [ ] navigation HUD
- [ ] offline download flow backed by real tile packs
- [ ] emergency UX hardening
- [ ] weather presentation using the shared icon family

## Track B — Maps & GIS
- [x] provider configuration abstraction
- [x] OSM-compatible attribution
- [x] GPX import/export foundation
- [x] offline capability contract
- [x] offline region model validation
- [x] persistent offline region state store
- [ ] `MapService` interface enforcement across features
- [ ] production vector-tile provider selection
- [ ] offline region downloader with pause/resume/update/delete
- [ ] elevation/profile provider
- [ ] routing engine evaluation and integration
- [ ] geospatial cache and tile budget controls

## Track C — Official data
- [x] AEMET provider-neutral contract
- [x] AEMET OpenData adapter foundation
- [x] provenance/freshness model
- [x] expiring runtime credential contract
- [ ] secure production gateway/runtime secret injection
- [ ] cache + retry/backoff + 429 handling policy
- [ ] official warning/CAP adapter
- [ ] wildfire/disaster adapters
- [ ] protected-area and environmental data
- [ ] stale-data safeguards at UI/query level

## Track D — Safety
- [x] GPS foundation
- [x] trusted contacts foundation
- [x] temporary location-sharing policy
- [x] SOS domain foundation
- [x] Rescue Link anti-abuse policy foundation
- [ ] 112 platform handoff hardening
- [ ] battery/connectivity telemetry in emergency snapshot
- [ ] emergency-session expiry enforcement
- [ ] end-to-end SOS tests on real devices

## Track E — Nature & pets
- [x] pet profiles
- [x] route compatibility foundation
- [x] wildlife encounter guidance foundation
- [ ] heat/water/shade factors from verified sources
- [ ] sensitive habitat protection
- [ ] conservation-aware recommendations
- [ ] Natura Protect index

## Track F — Platform
- [x] Flutter architecture targeting mobile, web and desktop
- [ ] Android production build validation
- [ ] iOS production build validation
- [ ] Web/PWA validation
- [ ] Windows validation
- [ ] macOS validation
- [ ] Linux validation
- [ ] platform-specific permission adapters
- [ ] wearable/GNSS/Bluetooth integration contracts

## Track G — Security & privacy
- [x] secure local storage foundation
- [x] permission minimization policy foundation
- [x] temporary location-sharing policy
- [ ] retention matrix enforcement
- [ ] audit events
- [ ] threat model review
- [ ] dependency/SBOM controls
- [ ] API authentication/authorization layer
- [ ] abuse/rate-limit controls

## Track H — Quality & delivery
- [x] unit tests for core GPX/safety/pet logic
- [x] CI static analysis/test workflow
- [x] dependency scanning baseline
- [ ] integration tests
- [ ] E2E tests
- [ ] offline/GPS/map test matrix
- [ ] accessibility test suite
- [ ] performance/battery tests
- [ ] release checklist and signed artifacts

## Immediate execution order

1. Keep the AEMET credential-expiry guard and move the production key behind a trusted gateway/runtime boundary.
2. Build the normalized official-alert model and AEMET CAP adapter.
3. Enforce the provider-neutral `MapService` boundary across map-dependent features.
4. Connect the persistent offline-region state to a real licensed vector-tile/offline provider; do not fake downloads.
5. Benchmark current `maplibre_gl` 0.27.x against `flutter_map` on Android/iOS/Web, while retaining a desktop-capable fallback.
6. Evaluate `maplibre_flutter_gpu` separately for desktop only after release-mode validation.
7. Add routing/elevation providers only after licence/cost/coverage validation.
8. Harden SOS and Rescue Link with expiry, device-state capture and end-to-end tests.

## Delivery rule

A track may use mock adapters or deterministic local fixtures while upstream credentials/data feeds are unavailable. Production integration must never be faked as live data.
