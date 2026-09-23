# P0 Tooling Registry

| Capability | Reused component | Version | License | Scope | Status / production gate |
|---|---|---:|---|---|---|
| Map renderer | flutter_map | 8.3.2 | BSD-3-Clause | Flutter all platforms | Adopted; provider and attribution audit |
| Native offline raster MBTiles | flutter_map_mbtiles | 1.0.4 | MIT | Android/iOS/Linux/macOS/Windows | Adopted; archive licensing and storage tests |
| MBTiles reader | mbtiles | 0.4.2 | BSD-3-Clause | Native runtime | Adopted; integrity/corruption tests |
| Web/hosted PMTiles path | flutter_map_pmtiles | 1.0.5 | MIT | Web + native | Candidate; use for provider-hosted PMTiles and Web path |
| HTTP transfer | Dio | 5.11.1 | MIT | Flutter platforms | Adopted; TLS, cancellation, resume, retry tests |
| Hash verification | crypto | 3.0.7 | BSD-3-Clause | Flutter all platforms | Adopted; SHA-256 mandatory before ready |
| GPS | geolocator | 14.0.3 | MIT | Flutter supported platforms | Adopted; native permission/background capability audit |
| Location map UX | flutter_map_location_marker | 10.3.0 | MIT-style | Flutter supported platforms | Adopted; current-location and heading UX |
| Map orientation | flutter_map_compass | 1.1.1 | MIT | flutter_map | Adopted |
| GPX | gpx | 2.5.0 | Apache-2.0 | Flutter all platforms | Adopted; supports current Dart baseline |
| Battery telemetry | battery_plus | 7.1.1 | BSD-3-Clause | Android/iOS/macOS/Web/Linux/Windows | Adopted; device capability fallback |
| Routing/elevation | Valhalla | 3.9.0 | MIT | Backend / future offline runtime | Adapter adopted; self-hosting/data/capacity gate |
| Routing abstraction | routing_engine | 0.6.3 | BSD-3-Clause | Flutter all platforms | Research only; too new for P0 lock-in |
| Gateway runtime | Shelf | 1.4.2 | BSD-3-Clause | Backend | Adopted; auth/rate limits/observability |
| Gateway router | shelf_router | 1.1.4 | Apache-2.0 | Backend | Adopted; API contract tests |
| Background maintenance | workmanager | 0.10.10 | MIT | Android/iOS/macOS/Web | Candidate for periodic sync/maintenance; not continuous GPS |
| Relational local database | Drift | 2.35.0 | MIT | Flutter/Dart | Candidate for future relational growth; Hive retained for current P0 |
| Offline tile manager | offline_tiles | 0.5.10 | MIT | Native Flutter | Research only; recently published, evaluate before adoption |

## Rules

1. No dependency is promoted to production solely because it is popular.
2. License, platform support, maintenance, security advisories and operational cost must be reviewed before production release.
3. Provider data licenses are separate from software licenses and must be recorded per dataset.
4. New dependencies for safety-critical paths require a replacement/fallback plan.
5. The registry must match versions intentionally selected in pubspec/pubspec.lock; transitive versions are not claimed as direct dependencies.
6. Avoid dependency duplication when an existing package already covers the requirement.
7. Candidate packages remain isolated until compatibility, maintenance and production behavior are validated.
8. Offline map archives must come from a source whose license explicitly permits the intended download/cache/distribution model.
