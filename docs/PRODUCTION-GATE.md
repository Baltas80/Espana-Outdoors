# España Outdoor — Production Gate

**Baseline:** 2026-09-23

This gate prevents the project from declaring production readiness while critical live-data, offline-map, emergency, security, or platform guarantees remain unverified.

## Current baseline

- Flutter application foundation exists with layered architecture, Riverpod, go_router, flutter_map, GPS, GPX, local persistence, secure storage and offline-region state.
- Provider-neutral `MapService` exists and offline region lifecycle is separated from the concrete renderer.
- AEMET is modelled behind a provider-neutral weather contract, but production credential handling belongs in the server-side Live Data Gateway.
- CI and dependency/security baselines exist, but cross-platform release validation is not complete.

## Release blockers

### P0 — must be closed before public production

1. **Live Data Gateway:** authenticated client API, provider credentials only in runtime secret storage, rate limiting, cache, retry/backoff, provenance and stale/error semantics.
2. **AEMET credential lifecycle:** monitor expiry and rotate before 15 October 2026 for legacy non-expiring keys; new keys have three-month validity.
3. **Offline maps:** only use a provider/infrastructure whose licence explicitly permits offline/prefetch distribution. Never bulk-download public OSM tile servers.
4. **Offline correctness:** a region becomes `ready` only after the provider confirms materialization; pause/resume/delete/update must be tested with interruption and low-storage scenarios.
5. **SOS:** real-device tests for 112 handoff, trusted-contact flow, temporary location sharing, battery/connectivity snapshot and emergency-session expiry.
6. **Privacy/security:** retention enforcement, authentication/authorization, abuse controls, secret scanning, SBOM/dependency review and emergency-location access controls.
7. **Platform matrix:** release builds and critical flows validated on Android, iOS/iPadOS, Web/PWA, Windows, macOS and Linux where supported by the selected feature set.

### P1 — required for a credible MVP

- navigation HUD and route-detail production UX;
- weather and official-alert presentation with freshness/provenance;
- routing/elevation provider selected after licence, coverage, performance and cost validation;
- accessibility and offline/GPS integration suites;
- observability for crashes, latency, provider failures and critical emergency events;
- signed release artifacts and rollback procedure.

### P2 — post-MVP differentiation

- Rescue Link operational network and verified responder roles;
- Natura Protect, sensitive-habitat protection and conservation index;
- fauna/flora identification and contextual guidance;
- semantic search and AI recommendations;
- community reports and professional/partner workflows;
- wearables/GNSS/Bluetooth integrations and monetization.

## Technical decisions currently locked

- Do not couple product features directly to a map vendor.
- Do not expose provider API keys in Flutter/mobile/web artifacts.
- Do not treat community or derived recommendations as official alerts.
- Do not expose sensitive wildlife coordinates.
- Do not present stale provider data as current.
- Do not use public OSM tile servers for offline prefetching.
- Do not implement safety-critical functionality with an unverified mock and label it production-ready.

## Validation evidence required

Every P0/P1 item must have one of:

- automated test result;
- deterministic integration fixture;
- real-device/platform validation record;
- provider/licence evidence;
- security review evidence;
- operational runbook/checklist.

A feature without evidence remains `prepared`, not `production-ready`.
