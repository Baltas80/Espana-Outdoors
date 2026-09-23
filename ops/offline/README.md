# Offline map production pipeline

## Architecture

España Outdoor does not bulk-download tiles from the public OpenStreetMap tile servers. Those servers prohibit bulk/offline prefetching and are not a production dependency for the app. cite not embedded

The production artifact pipeline is:

1. Download the Spain regional OpenStreetMap extract from Geofabrik.
2. Build the basemap PMTiles with the mature Protomaps Basemaps/Planetiler toolchain.
3. Store the immutable PMTiles artifact in application-controlled object storage/CDN.
4. Publish catalog metadata containing provider ID, licence URL, attribution, size, version timestamp and SHA-256.
5. The mobile app downloads only from the approved catalog and verifies the artifact before promotion to ready.

## Data / licence

OSM-derived data is distributed under ODbL. The map must visibly attribute OpenStreetMap and make the licence available. Derived databases retain the applicable share-alike obligations.

Protomaps Basemap tilesets are OSM-derived Produced Works under ODbL; the basemap tooling is BSD-3-Clause. The application must retain the relevant notices and display OSM attribution in the map UI.

## Source acquisition

Example Spain extract:

    https://download.geofabrik.de/europe/spain-latest.osm.pbf

Record the exact extract timestamp, upstream URL and SHA-256 in the release/build record. Do not rely on the mutable latest filename as the version identifier.

## PMTiles build

Use the pinned Protomaps Basemaps/Planetiler build in CI or a controlled map-builder host. Do not generate artifacts on developer laptops for production distribution.

Minimum output evidence:

- source PBF URL/date/digest;
- basemap tool commit/version;
- output PMTiles SHA-256;
- output size;
- maximum zoom;
- style version/digest;
- licence/attribution manifest.

## Object storage

PMTiles should be stored as immutable versioned objects behind HTTPS. The catalog points to the exact object, not a mutable latest URL.

Recommended layout:

    /offline/<region-id>/<version>/<artifact>.pmtiles

The object store may be S3-compatible, Cloudflare R2, or another controlled storage service. Access credentials belong only to infrastructure; the mobile app receives a public read URL for the immutable artifact.

## Catalog contract

Each entry must contain:

- id
- name
- description
- providerId = approved-pmtiles-catalog
- licenseUrl (HTTPS)
- attribution
- downloadUrl (HTTPS)
- sizeBytes
- updatedAt
- sha256

An entry missing any of these fields is rejected by the client.

## Update / rollback

Publish a new immutable version first. Verify its checksum and manifest. Only then point the catalog to the new version. Keep the previous artifact until the new version has passed mobile smoke tests so rollback is immediate.

Never overwrite an already-published versioned object.
