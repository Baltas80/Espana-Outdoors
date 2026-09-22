# ADR-0003 — Routing, elevation and live-alert boundaries

**Status:** accepted for Phase 1 implementation

## Context

España Outdoor needs route calculation, elevation and live risk information without coupling product logic to one vendor. Safety decisions require explicit provenance and expiry; stale or missing data must never be interpreted as safe.

## Decisions

### Routing

Use a provider-neutral `RoutingService` and `RoutingRequest`/`RoutingResult` domain model. Valhalla is the first production candidate, hosted by España Outdoor or controlled infrastructure rather than relying on a public demo endpoint for end-user traffic.

The app must retain the ability to replace Valhalla with another engine without changing route discovery, navigation or readiness logic.

### Live alerts

Use a provider-neutral `AlertService`. Every alert preserves authority (`official` or `espanaOutdoor`), type, severity, confidence, source, issue/update timestamps and explicit validity end time. Official alerts outrank first-party advisory signals. Expired alerts must not participate in route readiness decisions.

### AEMET

AEMET OpenData remains the official weather adapter. Its current API-key policy requires server-side rotation and expiry monitoring before production.

## Consequences

- Product code is insulated from routing and alert vendor changes.
- Controlled routing infrastructure and regional extracts remain possible.
- Safety logic can audit why an alert influenced a decision.
- Provider outage can degrade to cached/explicitly stale information instead of silently claiming safety.
