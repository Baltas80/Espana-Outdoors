# ADR-0002 — Reuse-first engineering strategy

## Status
Accepted for the MVP and production architecture.

## Decision
España Outdoor will **reuse mature infrastructure and libraries first** and write custom code only where it creates product differentiation or safety-critical policy.

The default sequence for a new capability is:

1. Existing Flutter/Dart package or platform API.
2. Mature open-source engine/service with a permissive license and active maintenance.
3. Managed provider behind an internal adapter when operating it ourselves is not justified.
4. Small España Outdoor adapter/domain layer.
5. New implementation only when the above options cannot meet the product, licensing, privacy, offline or safety requirements.

The application must not couple product/domain code directly to a provider. Provider-specific code belongs behind interfaces such as `MapService`, `RoutingService`, `ElevationService`, `WeatherService`, `AlertService`, `StorageService` and `EmergencyService`.

## Current reuse decisions

| Capability | Reuse candidate | Role in España Outdoor | Decision |
|---|---|---|---|
| Flutter UI/runtime | Flutter | Multiplatform application shell | Keep |
| State | Riverpod | Dependency injection/state | Keep |
| Navigation | go_router | Application navigation | Keep |
| Map rendering | flutter_map | Vendor-neutral map client | Keep for MVP |
| Location | geolocator | GPS/location access | Keep |
| Connectivity | connectivity_plus | Network state | Keep |
| Secure local secrets | flutter_secure_storage | Credentials/secrets only | Keep |
| Local persistence | Hive CE | Existing route/offline persistence | Keep until a measured limitation appears |
| GPX | gpx | Import/export | Keep |
| Offline raster/vector packaging | MBTiles / PMTiles | Region packages; avoid public OSM tile bulk downloads | Evaluate as the production offline format |
| Offline tile caching | flutter_map built-in caching / MIT alternatives | Opportunistic cache | Prefer permissive-license options; do not add GPL by default |
| Routing | Valhalla | Server and future offline routing engine | Preferred candidate; adapter required |
| Elevation | Valhalla elevation + official DEM data | Baseline elevation service | Prefer engine/data reuse; no custom routing engine |
| GIS processing | GDAL/PROJ/PostGIS | Backend/data pipeline | Reuse rather than implement GIS algorithms in Dart |
| Observability | OpenTelemetry + Sentry/Prometheus/Grafana as appropriate | Telemetry and operations | Evaluate during backend hardening |

## Routing policy

Valhalla is the primary engine candidate because it already provides pedestrian/bicycle/vehicle routing, turn-by-turn narratives, map matching, isochrones, elevation queries, and offline-capable tiled data. España Outdoor owns the outdoor policy layer: route safety, terrain/exposure scoring, closures, official warnings, pet constraints, conservation restrictions and the final recommendation.

The routing engine is therefore **not** the product. It supplies geometry, costs and navigation primitives; España Outdoor supplies the decision system around them.

## Offline map policy

Do not use public `tile.openstreetmap.org` servers for bulk/offline downloads. Offline regions must come from a provider/source whose usage terms explicitly permit the intended distribution and caching model.

Prefer standard region formats (MBTiles/PMTiles) so the data pipeline is independent of the Flutter map renderer. The client should consume an abstract offline-map source rather than knowing how the region was generated.

GPL components are not automatically rejected, but they require a separate legal/licensing decision before entering the application dependency graph. For a potentially proprietary commercial product, prefer BSD/MIT/Apache-compatible components when they provide equivalent functionality.

## What remains custom

Custom code is reserved for the areas that define España Outdoor:

- outdoor route suitability and safety policy;
- elevation/terrain/exposure/isolation interpretation;
- live information fusion and freshness/provenance;
- official-alert normalization and safety policy;
- SOS and privacy-preserving emergency flows;
- Rescue Link authorization, risk gates and temporary disclosure;
- conservation/Natura Protect rules;
- pet compatibility policy;
- España Outdoor UX, Design System and product workflows;
- provider adapters and deterministic fallbacks;
- audit/security controls specific to emergency data.

## Dependency admission checklist

Before adding a dependency, record:

- license and redistribution implications;
- maintenance/activity and release history;
- platform support;
- security posture and transitive dependencies;
- offline behaviour;
- performance and battery impact;
- API stability;
- data/privacy implications;
- cost, quotas and rate limits;
- lock-in and migration path;
- whether the capability can be removed without rewriting the domain layer.

## Consequence

The codebase will contain more adapters/contracts and less duplicated infrastructure code. This is intentional. It reduces maintenance, accelerates delivery and makes provider replacement possible without rewriting the product.
