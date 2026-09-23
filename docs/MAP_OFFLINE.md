# MapLibre + PMTiles + offline

## Architecture

España Outdoor uses MapLibre Flutter as the primary renderer on Android, iOS and Web, with PMTiles vector archives as the map distribution format. Desktop keeps the existing GIS renderer fallback until stable native MapLibre support is available for those targets.

The application does not embed a third-party demo tileset. A production/staging build must provide `MAP_PMTILES_URL` or a configured `MAP_STYLE_JSON` whose PMTiles source points to an approved España Outdoor-controlled distribution endpoint.

For mobile, a downloaded `.pmtiles` region in the application-support `offline_regions` directory takes precedence over the remote PMTiles endpoint. Downloads use `background_downloader`, which provides persistent/background transfers and pause/resume support on the supported native platforms.

## Configuration

Recommended build-time variables:

- `MAP_PMTILES_URL`: HTTPS URL of the approved vector PMTiles archive.
- `MAP_STYLE_URL`: optional HTTPS style JSON. The provider replaces `__PMTILES_URL__` in that JSON when present.
- `MAP_STYLE_JSON`: optional inline style JSON for controlled builds. Prefer a checked-in style or approved style endpoint rather than arbitrary runtime input.

A missing `MAP_PMTILES_URL` with no local offline archive is treated as a configuration error. This prevents the app from silently depending on a demonstration dataset.

## Offline lifecycle

1. The region catalog publishes an immutable region id, URL, byte size, update timestamp and optional SHA-256 digest.
2. `background_downloader` stores the completed archive under application support in `offline_regions/<region>.pmtiles`.
3. Mobile MapLibre resolves the newest local PMTiles archive before using the configured remote archive.
4. If connectivity disappears, the local archive remains usable for map rendering.
5. Dynamic safety/weather information is never inferred from the age of the map archive; freshness must be represented separately.
6. A future update may publish a newer archive for the same region. The downloader can resume interrupted transfers where the origin supports HTTP range requests.

## Licensing and attribution

The basemap distribution must retain OpenStreetMap attribution and comply with the license of every included source. The repository contains only the rendering style and integration code; production map archives are distributed separately so they can be updated without shipping a new application binary.

## Security requirements

- Only HTTPS map endpoints are accepted for remote distribution in production.
- No provider API keys are committed to the repository.
- Offline package metadata must be treated as untrusted input and validated before use.
- Region archives should be published with SHA-256 digests; verification should occur before an archive becomes the active map source.
- Emergency and alert layers must remain logically separate from the basemap and must carry their own source, timestamp and validity metadata.

## Why PMTiles

PMTiles is an open, single-file tiled-data format designed for HTTP range access and direct cloud/object-storage distribution. This keeps the map stack portable and makes it possible to self-host the production archive instead of coupling the application to a proprietary map API.
