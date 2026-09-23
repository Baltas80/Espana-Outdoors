# ADR-0002: outdoor routing engine

- Status: Accepted for MVP integration
- Decision: use Valhalla behind `RoutingService`
- Scope: outdoor route calculation, map matching, matrices/isochrones where required, and elevation-aware routing when configured with suitable data

## Context

A proprietary routing engine would duplicate a mature graph/routing stack, increase operational risk and make the product harder to maintain. Spain Outdoor needs hiking/outdoor routing but does not need to own the routing algorithms themselves.

## Decision

Use Valhalla as the primary routing engine and keep all application code behind the provider-neutral `RoutingService` contract.

The client must not assume that Valhalla is always available. Online routing can fail over to a previously downloaded route or a locally available route representation. Navigation must never invent a recalculated path when the routing provider is unavailable.

## Data

- OpenStreetMap is the base network source where legally and operationally appropriate.
- Elevation uses an approved DEM pipeline and is stored with source metadata.
- Routing results are tagged with provider/version/time metadata when persisted.

## Consequences

### Positive

- Minimal proprietary routing code.
- Mature routing algorithms and map matching.
- Easier regional deployment and replacement of the engine later.
- Clear separation between routing infrastructure and Spain Outdoor product logic.

### Negative

- Valhalla requires operational infrastructure and regional data management.
- Routing quality depends on source data and profile configuration.
- Production costs include tile generation/storage and compute.

## Safety constraint

Routing is not a safety certification. Route status and the risk engine must separately evaluate closures, alerts, weather, terrain and other hazards.
