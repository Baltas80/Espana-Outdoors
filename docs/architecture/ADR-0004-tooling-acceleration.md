# ADR-0004 — Reuse mature tooling for P0 navigation and offline

Status: accepted for MVP evaluation

## Decisions

- Use flutter_map 8.3.2 as the current renderer boundary and flutter_map_mbtiles 1.0.4 plus mbtiles 0.5.1 for guaranteed local MBTiles archives on native platforms.
- Use Dio 5.11.1 for resumable HTTP archive downloads and cancellation/progress primitives.
- Use Valhalla 3.9.0 as the first routing/elevation adapter candidate. It provides route, elevation, map matching and tiled data suitable for regional/offline architectures.
- Use battery_plus 7.1.1 for cross-platform battery telemetry in emergency snapshots.
- Use crypto 3.0.7 for SHA-256 verification of offline artifacts.
- Use Shelf 1.4.2 and shelf_router 1.1.4 for the lightweight Live Data Gateway runtime, keeping provider credentials server-side.

## Constraints

- Public OSM tile servers are not used as an offline download source.
- MBTiles is the native-platform path; Web requires a separate PMTiles/browser implementation.
- Provider URLs are configuration for app features; provider adapters may own their documented upstream endpoint.
- Offline archives require a trusted checksum and provenance metadata before becoming ready.
- Valhalla public/demo infrastructure is not a production dependency.

## Rationale

These components are focused and reduce custom code in areas where existing implementations provide mature primitives: SQLite/MBTiles access, HTTP streaming, hashing, battery telemetry, routing and server middleware. Product-specific logic remains in provider-neutral contracts, safety policy, provenance and orchestration.

## References

- flutter_map_mbtiles: https://pub.dev/packages/flutter_map_mbtiles
- mbtiles: https://pub.dev/packages/mbtiles
- Dio: https://pub.dev/packages/dio
- battery_plus: https://pub.dev/packages/battery_plus
- crypto: https://pub.dev/packages/crypto
- Valhalla: https://github.com/valhalla/valhalla
- Shelf: https://pub.dev/packages/shelf
