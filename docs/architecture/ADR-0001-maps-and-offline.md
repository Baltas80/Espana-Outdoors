# ADR-0001 — Cartography, tiles and offline strategy

**Status:** Accepted for MVP; production provider validation required before public launch.

## Context

España Outdoor needs a provider-independent mapping layer, online and offline operation, vector/raster support, attribution, Spanish official data and the ability to change suppliers without rewriting product features.

The current Flutter client uses `flutter_map` behind `MapProviderConfig`. This is intentionally retained for the MVP because it is already integrated and keeps the map implementation portable across the project's target Flutter platforms.

## Research snapshot — 2026-09-22

### OpenStreetMap

OpenStreetMap data is open, but the public `tile.openstreetmap.org` service is not a production/offline tile CDN. OSMF explicitly prohibits bulk downloading and offline prefetching from that server and provides no SLA. It also requires visible attribution and a clear identifying User-Agent.

Decision: **never implement España Outdoor offline downloads against the public OSM tile server.** It may be used only for controlled development/low-volume interactive testing where policy requirements are satisfied.

Source: https://operations.osmfoundation.org/policies/tiles/

### MapLibre

MapLibre provides an open mapping stack with control over sources and styling. Current Flutter documentation covers vector/raster/GeoJSON sources, data-driven layers, user location, PMTiles and offline regions; the ecosystem also supports native Android, iOS, desktop and web components. Offline capabilities and platform parity still need to be validated against the exact package/version selected for production.

Sources:
- https://maplibre.org/
- https://maplibre.org/flutter-maplibre-gl/advanced/
- https://maplibre.org/flutter-maplibre-gl/layers/

### Commercial providers

MapTiler currently offers hosted and on-prem products, including MBTiles/GeoPackage processing and offline/self-hosted options. Pricing and license restrictions depend on product and deployment model, so a commercial production choice must be made only after traffic, MAU, offline distribution and B2C licensing are modelled.

Source: https://www.maptiler.com/cloud/pricing/

## Target architecture

```text
Flutter UI
   |
MapService (abstract)
   |
+--+-------------------+
|                      |
OnlineMapProvider      OfflineMapProvider
|                      |
Hosted vector/raster   Local MBTiles/PMTiles/vector store
|
MapProviderConfig / provider registry
```

The product layer must never depend directly on a provider SDK or tile URL.

## Production recommendation

1. Keep `flutter_map` for the immediate MVP while its current feature set is sufficient.
2. Build a provider-neutral `MapService` interface before adding offline downloads.
3. Evaluate a MapLibre-based renderer as the preferred production candidate if the exact Flutter package provides the required Android/iOS/Web/desktop parity at release time.
4. For offline maps, use self-hosted or explicitly licensed offline-capable tiles. Do not use public OSM raster tiles for prefetching.
5. Use OSM data with correct attribution, but treat data licensing and tile-service licensing as separate concerns.
6. Add official Spanish layers through independent data adapters rather than modifying the base map provider.

## Offline download contract

An offline region must have:

- stable region identifier
- bounding geometry
- zoom range
- style/version identifier
- source/provider identifier
- byte and tile estimates
- checksum/version metadata
- resumable download state
- pause/resume
- cancellation
- deletion
- update/invalidation strategy
- expiry/freshness policy
- storage quota guard
- attribution metadata

## Data layers

Official and open layers must preserve provenance:

- source name
- source URL
- licence
- attribution
- retrieved-at timestamp
- source update timestamp when available
- validity window
- transformation pipeline version
- confidence/quality state

## Weather source

AEMET OpenData exposes a REST API for reusable meteorological/climatological data. Current AEMET notices also document API-key expiry requirements for keys without an expiration date from 15 October 2026. The production connector must therefore support secret rotation and explicit key expiry metadata.

Sources:
- https://www.aemet.es/es/datos_abiertos/AEMET_OpenData
- https://opendata.aemet.es/centrodedescargas/novedades

## Non-goals for this ADR

This ADR does not approve a final commercial map vendor, routing engine or elevation provider. Those require measured load tests, license review, offline tests and cost modelling against real España Outdoor usage assumptions.
