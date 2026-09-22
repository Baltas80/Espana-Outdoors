# ADR-0002 — Routing, elevation and live-alert boundaries

**Status:** accepted for Phase 1 implementation

## Context

España Outdoor needs route calculation, elevation and live risk information without coupling product logic to one vendor. Safety decisions also require explicit provenance and expiry; stale or missing data must never be interpreted as safe.

## Decisions

### Routing

Use a provider-neutral `RoutingService` and `RoutingRequest`/`RoutingResult` domain model. The first production candidate is **Valhalla**, hosted by España Outdoor or a controlled infrastructure partner rather than relying on the public demo service for end-user traffic.

Valhalla is MIT licensed and currently provides routing, pedestrian costing, elevation sampling, map matching and tiled data designed to support regional extracts/offline use. Its public demo has fair-use/rate-limit constraints and is therefore not a production dependency for the app.

The app must retain the ability to replace Valhalla with another engine without changing route discovery, navigation or readiness logic.

### Live alerts

Use a provider-neutral `AlertService`. Every alert must preserve:

- authority (`official` or `espanaOutdoor`);
- type and severity;
- confidence;
- source name and URL;
- issue/update timestamps;
- explicit validity end time;
- optional source and region identifiers.

Official alerts always outrank first-party advisory signals. Expired alerts must not participate in route readiness decisions.

### AEMET

AEMET OpenData remains the authoritative weather adapter for Spain Outdoor's official weather layer. Its current API requires API keys and new keys expire after three months; keys without an expiry cease to be valid from 15 October 2026. Production access therefore belongs behind a backend/gateway with secret rotation and caching, not in the mobile client.

## Consequences

- Product code is insulated from routing and alert vendor changes.
- We can run controlled routing infrastructure and regional extracts.
- Safety logic can audit why an alert influenced a decision.
- Provider outage can degrade to cached/explicitly stale information instead of silently claiming safety.
- Additional implementation work remains for the production routing backend, elevation dataset pipeline and official-alert adapters.

## Sources

- Valhalla project and MIT license: https://github.com/valhalla/valhalla
- AEMET OpenData: https://opendata.aemet.es/
