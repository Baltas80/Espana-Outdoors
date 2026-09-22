# ADR 0003 - Provider-neutral offline maps

## Decision

España Outdoor keeps offline-map lifecycle and product state behind `MapService` and `OfflineRegionManager`. The application must not couple route, safety or UI logic to a specific map vendor.

## Rationale

Offline maps are a core product capability and a potential source of vendor lock-in and unexpected infrastructure cost. The repository already defines a provider-neutral `MapService` contract. The offline manager now persists region state separately from the concrete renderer/downloader.

## Requirements for a concrete provider

- Legal right to download and cache the selected map data.
- Explicit tile/vector/raster usage and attribution terms.
- Resumable downloads where supported.
- Deterministic style/version metadata.
- Storage-size estimation before download where technically possible.
- Safe cancellation, pause, resume and deletion.
- No credentials embedded in the client when the provider requires protected access; use a secure backend/token strategy.
- Clear fallback behavior when the provider is unavailable.

## Current status

The product layer is ready for a real provider adapter. Provider selection remains an engineering decision pending current verification of licensing, offline capabilities, coverage, performance and cost.

## Non-goals

This layer does not invent or silently scrape proprietary map data, and it does not claim that an offline region is ready until the provider adapter confirms successful preparation.
