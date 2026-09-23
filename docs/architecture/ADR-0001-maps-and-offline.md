# ADR-0001 — Cartography, tiles and offline strategy

**Status:** Accepted for MVP; production provider validation required before public launch.

## Context

España Outdoor needs a provider-independent mapping layer, online and offline operation, vector/raster support, attribution, Spanish official data and the ability to change suppliers without rewriting product features.

The current Flutter client uses `flutter_map` behind `MapProviderConfig`. It remains the safest immediate MVP baseline because it is already integrated and covers the full Flutter target matrix required by the product.

## Research snapshot — 2026-09-23

### OpenStreetMap

OpenStreetMap data is open, but the public `tile.openstreetmap.org` service is not a production/offline tile CDN. España Outdoor must not use it for bulk downloading or offline prefetching. Attribution and service-policy requirements remain mandatory.

Decision: **never implement España Outdoor offline downloads against the public OSM tile server.**

### MapLibre Flutter

The current `maplibre_gl` line is 0.27.1 and supports Android, iOS and Web. Its current feature matrix includes vector/raster/GeoJSON/PMTiles, user location and native offline regions on Android/iOS; offline regions are not supported on Web, and Windows/macOS/Linux are not supported by this package. Recent releases also added pause/resume and richer offline progress/status APIs, making it a strong mobile production candidate. The project explicitly warns that platform-view widgets must be overlaid rather than embedded in map layers.

MapLibre also has a newer `maplibre_flutter_gpu` package targeting iOS, Android, Windows, macOS and Linux, but Web is not supported and current Flutter GPU release constraints still require validation before it can become the common renderer.

Decision: **keep `flutter_map` as the cross-platform MVP renderer and prototype MapLibre behind the `MapService` boundary for mobile/vector/offline capabilities.** Do not perform a wholesale renderer migration until measured tests show a material product benefit and the desktop/web parity gap is solved.

Sources:
- https://pub.dev/packages/maplibre_gl/versions
- https://github.com/maplibre/flutter-maplibre-gl
- https://pub.dev/packages/maplibre_flutter_gpu
- https://maplibre.org/

### Commercial providers

Commercial providers can simplify hosted tiles, routing and offline distribution but introduce recurring cost, quotas and contractual lock-in. Pricing and licensing must be modelled against traffic, MAU, offline distribution and B2C use before selection.

## Target architecture

```text
Flutter UI
   |
MapService (abstract)
   |
+--+-----------------------+
|                          |
OnlineMapProvider          OfflineMapProvider
|                          |
Hosted vector/raster       Local MBTiles/PMTiles/vector store
|
MapProviderConfig / provider registry
```

The product layer must never depend directly on a provider SDK or tile URL.

## Production recommendation

1. Keep `flutter_map` for the immediate MVP.
2. Build and enforce a provider-neutral `MapService` before adding offline downloads.
3. Benchmark MapLibre 0.27.x on Android/iOS/Web for vector rendering, overlays, GPS-following and offline regions.
4. Evaluate `maplibre_flutter_gpu` separately for desktop once release-mode support and operational maturity meet production requirements.
5. Retain a desktop-capable renderer until a MapLibre path is production-ready across the selected targets.
6. For offline maps, use self-hosted or explicitly licensed offline-capable tiles. Do not use public OSM raster tiles for prefetching.
7. Use OSM data with correct attribution, but treat data licensing and tile-service licensing as separate concerns.
8. Add official Spanish layers through independent data adapters rather than modifying the base map provider.

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

AEMET OpenData exposes a REST API for reusable meteorological/climatological data. AEMET's current notices state that API keys without an expiration date will stop being valid on **15 October 2026**. España Outdoor therefore treats credential expiry as an explicit runtime invariant; see ADR-0004. Production should still put provider credentials behind a trusted gateway/runtime boundary with caching, retry/backoff, rate limiting and provider failover.

Sources:
- https://www.aemet.es/es/datos_abiertos/AEMET_OpenData
- https://opendata.aemet.es/centrodedescargas/novedades

## Non-goals for this ADR

This ADR does not approve a final commercial map vendor, routing engine or elevation provider. Those require measured load tests, license review, offline tests and cost modelling against real España Outdoor usage assumptions.
