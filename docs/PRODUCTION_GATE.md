# España Outdoor — Production Readiness Gates

**Status:** active CTO gate for Phase 0 → Phase 1.
**Baseline:** `master` at `16164d1b4202c3c771505d6bef146ff05fbf2072`.
**Last reviewed:** 2026-09-22.

This document converts the current repository state into explicit release gates. A feature is not considered production-ready merely because its UI exists: its data provenance, offline behavior, failure modes, privacy impact and tests must also be defined.

## Current baseline

The repository already contains a Flutter multiplatform foundation with Riverpod, routing, map/GPS layers, GPX persistence/import, offline-region persistence, privacy/security documentation, a premium Design System, weather iconography and CI/security workflows. The current architecture deliberately keeps the map provider behind an abstraction and rejects public OSM tile-server bulk/offline downloading.

## Release gates

### Gate A — Build and quality

- [ ] `flutter analyze` clean.
- [ ] Unit and integration tests green.
- [ ] Web, Android, iOS, Windows, macOS and Linux builds validated by CI or dedicated runners.
- [ ] No release-blocking dependency vulnerabilities.
- [ ] Crash/error observability enabled for production builds.

### Gate B — Map/GIS

- [ ] `MapService` remains provider-neutral.
- [ ] Production tile provider has explicit offline rights and attribution.
- [ ] Offline region downloads are resumable, cancellable, versioned and quota-aware.
- [ ] No production bulk download from `tile.openstreetmap.org`.
- [ ] Routing and elevation providers have documented licences, limits, cost and fallback behavior.

### Gate C — Live data

- [ ] Every dynamic source records source, attribution, retrieval time, source update time when available, validity and confidence.
- [ ] AEMET and other official connectors use runtime secret configuration, caching, retry/backoff and provider failure handling.
- [ ] Official alerts remain visually and semantically distinct from España Outdoor advisories.
- [ ] Stale data is surfaced as stale; it is never silently presented as current.

### Gate D — Safety

- [ ] SOS works with degraded/no connectivity for all locally available critical data.
- [ ] 112 remains the official emergency path.
- [ ] Route plans have explicit start/return expectations and trusted-contact handling.
- [ ] Emergency location data has minimum retention and explicit expiry.
- [ ] Rescue Link cannot dispatch volunteers into prohibited/high-risk scenarios.
- [ ] Volunteer sharing starts with approximate/minimal information and escalates only after acceptance.

### Gate E — Privacy and security

- [ ] No secrets, API keys or credentials are committed.
- [ ] Exact, approximate, private, temporary and shared locations are distinct data classes.
- [ ] Access control follows least privilege.
- [ ] Sensitive emergency and wildlife coordinates are protected and expire where applicable.
- [ ] Rate limiting, input validation, abuse controls and secure logging are present at service boundaries.
- [ ] RGPD records, retention rules and user-facing consent/permission flows are documented before production launch.

### Gate F — Accessibility and UX

- [ ] WCAG 2.2 AA baseline for normal product surfaces.
- [ ] Safety states never depend on colour alone.
- [ ] Touch targets meet the Design System minimum.
- [ ] Screen readers, keyboard navigation, text scaling and reduced-motion behavior are tested.
- [ ] Map-first mobile, split tablet and desktop layouts are validated.

### Gate G — Data protection and conservation

- [ ] Sensitive wildlife locations are generalized or suppressed.
- [ ] Temporary reports have explicit freshness/expiry rules.
- [ ] Natura Protect and conservation recommendations do not expose sensitive breeding/refuge locations.
- [ ] Official, confirmed, community and stale information have separate trust states.

## Immediate Phase 1 implementation order

1. Complete map/offline provider implementation behind `MapService`.
2. Finish route analytics and GPX round-trip tests.
3. Wire weather through secure runtime configuration and stale-data handling.
4. Add live route-status and hazard domain models with provenance/freshness.
5. Harden route planning and SOS offline flows.
6. Expand CI to platform builds and security/quality gates.
7. Add production observability and release configuration.

## Explicitly deferred until the MVP safety core is solid

- Volunteer Rescue Link dispatch.
- AI safety decisions.
- Visual species identification used as a safety decision.
- Monetization.
- International expansion.

These features may be designed and stubbed behind interfaces, but they must not be presented as production capabilities until their safety, privacy and operational gates are satisfied.
