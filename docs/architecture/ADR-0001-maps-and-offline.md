# ADR-0001 — Cartography, tiles and offline strategy

**Status:** Accepted for MVP; production provider validation required before public launch.

## Context

España Outdoor needs a provider-independent mapping layer, online and offline operation, vector/raster support, attribution, Spanish official data and the ability to change suppliers without rewriting product features.

The current Flutter client uses `maplibre_gl` behind the provider-neutral `MapService` boundary. PMTiles are the current offline/vector package path. The active product target is Android and iOS/iPadOS; Web and desktop are not release targets for this MVP.

## Research snapshot — 2026-09-23

### OpenStreetMap

OpenStreetMap data is open, but the public `tile.openstreetmap.org` service is not a production/offline tile CDN. OSMF explicitly prohibits bulk downloading and offline prefetching from that server and provides no SLA. It also requires visible attribution and a clear identifying User-Agent.

Decision: **never implement España Outdoor offline downloads against the public OSM tile server.** It may be used only for controlled development/low-volume interactive testing where policy requirements are satisfied.

Source: https://operations.osmfoundation.org/policies/tiles/

### MapLibre

MapLibre remains the leading open-source candidate for the vector-map production path. Current Flutter options need to be evaluated by target platform rather than treated as a single universal renderer.

The `maplibre_flutter_gpu` package currently targets iOS, Android, macOS, Windows and Linux, but not Web. It requires Flutter 3.47 or later, and its current documentation notes that Flutter 3.47 does not yet support Flutter GPU in Windows/Linux release builds. That makes it unsuitable as the sole production renderer for España Outdoor's required Web + desktop matrix at the current stage.

Decision: **retain `maplibre_gl` for the mobile MVP.** Validate it on Android and iOS/iPadOS with the production PMTiles style, GPS-following, overlays and representative offline regions. Keep provider-facing configuration behind the map abstraction.

Sources:
- https://maplibre.org/
- https://pub.dev/packages/maplibre_flutter_gpu
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

1. Keep the provider-neutral `MapService` boundary enforced across feature code.
2. Validate `maplibre_gl` on Android/iOS with the production PMTiles style, GPS-following, overlays and representative offline regions.
3. Use a first-party PMTiles catalog for offline artifacts. The reference pipeline is OSM-derived Spain extract → Protomaps Basemaps/Planetiler → immutable PMTiles object → HTTPS catalog entry.
4. Do not use public OSM raster/vector tile servers for bulk prefetch or offline delivery.
5. Publish OSM/ODbL attribution and all additional data-source licences with each catalog artifact.
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

Offline packages must carry provider ID, HTTPS licence URL and attribution before a region can reach `ready`.

### IGN/CNIG

IGN states that its geographic information policy is compatible with CC BY 4.0, with the applicable general conditions and attribution requirements. España Outdoor must preserve IGN/CNIG attribution and source metadata in derived layers and exports.

Source: https://www.ign.es/web/en/ign/portal/politica-datos

## Weather source

AEMET OpenData provides a REST API for reusable meteorological/climatological data. Current AEMET communications published in July 2026 state that API keys without an expiration date will stop being valid from **15 October 2026**, while new keys have a three-month validity period. The connector therefore must treat the API key as a renewable runtime secret rather than a long-lived repository credential.

AEMET also currently exposes daily and hourly municipality prediction endpoints, which are relevant to the MVP weather adapter.

Sources:
- https://www.aemet.es/es/datos_abiertos/AEMET_OpenData
- https://opendata.aemet.es/centrodedescargas/novedades

## Offline provider decision — 2026-09-23

For the mobile MVP, the approved implementation path is a first-party OSM-derived PMTiles catalog rather than a public tile service or a proprietary offline SDK. Geofabrik publishes daily Spain OSM extracts; Protomaps Basemaps provides a mature Planetiler-based PMTiles build path and MapLibre styles. Production artifacts remain immutable and must pass checksum, licence and attribution validation before publication.

Sources:
- https://download.geofabrik.de/europe/spain.html
- https://github.com/protomaps/basemaps
- https://www.openstreetmap.org/copyright

This is an implementation path, not a claim that the production artifact pipeline has already been deployed.

## Non-goals for this ADR

This ADR does not approve a final commercial map vendor, routing engine or elevation provider. Those require measured load tests, license review, offline tests and cost modelling against real España Outdoor usage assumptions.
