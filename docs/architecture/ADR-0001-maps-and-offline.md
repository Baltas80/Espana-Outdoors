# ADR-0001 — Cartography, tiles and offline strategy

**Status:** Accepted for MVP; production provider validation required before public launch.

## Context

España Outdoor needs a provider-independent mapping layer, online and offline operation, vector/raster support, attribution, Spanish official data and the ability to change suppliers without rewriting product features.

The current Flutter client uses `flutter_map` behind `MapProviderConfig`. This is intentionally retained for the MVP because it is already integrated, BSD-3-Clause licensed, and supports Android, iOS, Linux, macOS, Web and Windows.

## Research snapshot — 2026-09-22

### OpenStreetMap

OpenStreetMap data is open, but the public `tile.openstreetmap.org` service is not a production/offline tile CDN. OSMF explicitly prohibits bulk downloading and offline prefetching from that server and provides no SLA. It also requires visible attribution and a clear identifying User-Agent.

Decision: **never implement España Outdoor offline downloads against the public OSM tile server.** It may be used only for controlled development/low-volume interactive testing where policy requirements are satisfied.

Source: https://operations.osmfoundation.org/policies/tiles/

### MapLibre

MapLibre is the leading open-source candidate for the vector-map production path. Its Flutter ecosystem supports vector/raster/GeoJSON/PMTiles sources, data-driven layers and user location. Current `maplibre_gl` releases provide Android/iOS/Web support and offline regions on Android/iOS, but do not support Windows/macOS/Linux targets. A separate newer `maplibre` package targets broader Flutter platform coverage but requires validation of API maturity and offline parity before adoption.

Decision: **do not replace `flutter_map` yet.** Evaluate MapLibre as a platform-specific production renderer while preserving the provider-neutral map abstraction and a full Flutter fallback for desktop.

Sources:
- https://maplibre.org/
- https://maplibre.org/flutter-maplibre-gl/advanced/
- https://pub.dev/packages/maplibre_gl
- https://pub.dev/packages/maplibre

### Commercial providers

Commercial providers can simplify hosted tiles, routing and offline distribution but introduce recurring cost, quotas and contractual lock-in. Pricing and licensing must be modelled against traffic, MAU, offline distribution and B2C use before selection.

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

1. Keep `flutter_map` for the immediate MVP.
2. Build and enforce a provider-neutral `MapService` before adding offline downloads.
3. Benchmark MapLibre on Android/iOS/Web for vector rendering, overlays, GPS-following and offline regions.
4. Retain a desktop-capable renderer until a MapLibre desktop path is production-ready for the selected package.
5. For offline maps, use self-hosted or explicitly licensed offline-capable tiles. Do not use public OSM raster tiles for prefetching.
6. Use OSM data with correct attribution, but treat data licensing and tile-service licensing as separate concerns.
7. Add official Spanish layers through independent data adapters rather than modifying the base map provider.

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

AEMET OpenData exposes a REST API for reusable meteorological/climatological data. Current AEMET notices also document API-key expiry requirements for keys without an expiration date from 15 October 2026. The production connector now exists behind `WeatherService`; it must still be wired to secure runtime configuration, caching, retry/backoff and a provider failover strategy.

Sources:
- https://www.aemet.es/es/datos_abiertos/AEMET_OpenData
- https://opendata.aemet.es/centrodedescargas/novedades

## Non-goals for this ADR

This ADR does not approve a final commercial map vendor, routing engine or elevation provider. Those require measured load tests, license review, offline tests and cost modelling against real España Outdoor usage assumptions.
