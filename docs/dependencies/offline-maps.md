# Offline maps dependency decision

## flutter_map_mbtiles

- Version evaluated: 1.0.4
- License: MIT
- Purpose: local MBTiles rendering through flutter_map on native desktop/mobile platforms.
- Platforms: Android, iOS, Linux, macOS, Windows.
- Web: not supported by this package because it relies on SQLite.
- Decision: approved as the native MBTiles rendering adapter; keep it behind the provider-neutral map boundary.

## Important product constraint

This package renders local MBTiles; it does not grant rights to download or redistribute map data. España Outdoor must obtain map data from a source whose license and operational terms explicitly permit the intended download, caching and distribution model.

## Source policy

Do not bulk-download from public OSM tile servers. Offline packages must be generated or obtained from an authorized source and carry attribution/license metadata.

## Web strategy

Keep the offline package contract provider-neutral. Web will use a separate browser-compatible strategy rather than forcing the native SQLite/MBTiles implementation into the web build.
