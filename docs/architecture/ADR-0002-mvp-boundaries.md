# ADR-0002 — MVP service boundaries and safety contracts

**Status:** Accepted for MVP architecture.

## Decision

Keep the client modular and provider-neutral, but avoid premature microservices. Domain boundaries are explicit interfaces now; backend services can be introduced behind them when scale, live-data fan-out, emergency coordination or community ingestion requires them.

Required client-facing abstractions:

- `MapService`
- `RoutingService`
- `WeatherService`
- `AlertService`
- `EmergencyService`
- `StorageService`
- `AuthService`
- `AIService`

Critical dynamic records must carry, where applicable:

- source/provider identifier
- source URL or source reference
- retrieved-at timestamp
- source update timestamp when available
- validity/expiry window
- confidence/quality state
- transformation/pipeline version

## Safety assessment contract

The route decision engine must never infer safety from a single signal. Its output is one of:

- `APTO`
- `PRECAUCIÓN`
- `NO_RECOMENDADO`
- `SIN_DATOS_SUFICIENTES`

Every non-trivial result includes machine-readable reasons and human-readable explanation. A missing critical source cannot silently become `APTO`.

## Emergency contract

Emergency location is classified as temporary sensitive data. Exact location is shared only when the user explicitly triggers a workflow that requires it and only with the intended recipient. Approximate location is the default for Rescue Link discovery. Emergency records have explicit expiry and must not become durable route history by accident.

## Offline contract

Critical offline data is separated into:

1. navigation substrate: map, route geometry, elevation and GPS state;
2. safety substrate: cached hazards, official alerts and emergency instructions with freshness metadata;
3. personal substrate: local recordings, plans, contacts and pending sync operations.

When offline, stale dynamic data must be visibly marked stale and must not be represented as current.

## Provider failure

Provider adapters fail closed for safety-critical information. UI may show unavailable/stale state and alternate sources; it must not fabricate a replacement value.

## Release gate

A feature involving emergency, hazard or live-data decisions cannot be marked production-ready until it has unit, integration, offline and failure-mode tests plus provenance/expiry verification.
