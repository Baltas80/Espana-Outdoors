# R2 production bootstrap — Spain PMTiles

This repository cannot create the user's Cloudflare account, domain or secret values. The production deployment becomes executable once the Cloudflare R2 resources and GitHub Actions environment are configured.

## 1. Cloudflare R2

Create a production bucket, for example:

    espana-outdoor-maps

Do not expose the bucket through the `r2.dev` development hostname. For production, attach a custom domain controlled by España Outdoor. Cloudflare documents `r2.dev` as development-only and custom domains as the production path.

## 2. R2 API credentials

Create an R2 API token with Object Read & Write permission scoped to the production bucket.

Store:

- Access Key ID
- Secret Access Key

Do not commit either value.

## 3. GitHub environment

Create the environment:

    maps-production

Required environment secrets:

    R2_ACCOUNT_ID
    R2_ACCESS_KEY_ID
    R2_SECRET_ACCESS_KEY

Required environment variables:

    R2_BUCKET
    MAPS_PUBLIC_BASE_URL
    MAPS_LICENSE_URL
    MAPS_ATTRIBUTION

Example values (replace them; these are not production values):

    R2_BUCKET=espana-outdoor-maps
    MAPS_PUBLIC_BASE_URL=https://maps.<YOUR-CONTROLLED-DOMAIN>
    MAPS_LICENSE_URL=https://opendatacommons.org/licenses/odbl/1-0/
    MAPS_ATTRIBUTION=© OpenStreetMap contributors

## 4. CORS

For the current mobile architecture, GET/HEAD are sufficient. Keep Range-related headers available for clients that inspect them.

Use `ops/offline/r2/cors.json` as the starting policy, replacing the placeholder origin with the real controlled application domain when a browser client requires CORS.

## 5. Build and publish

Run:

    GitHub Actions → PMTiles production release → Run workflow

Supply:

- an immutable map release version, e.g. `2026-09-24`;
- an immutable/versioned Geofabrik OSM PBF URL.

The workflow:

1. downloads the specified Spain PBF;
2. records its SHA-256;
3. runs pinned Planetiler 0.10.2;
4. generates `spain.pmtiles`;
5. verifies the PMTiles archive with pinned PMTiles CLI 1.31.2;
6. calculates the PMTiles SHA-256;
7. uploads immutable objects to R2;
8. publishes the signed metadata contract;
9. verifies HTTPS + Range support.

## 6. Production URL

The final client value is the immutable public object URL:

    MAP_PMTILES_URL=https://maps.<YOUR-CONTROLLED-DOMAIN>/basemap/spain/<VERSION>/spain.pmtiles

It must be introduced through the release environment, never hard-coded in Dart.

## 7. Acceptance gate

The map is not production-ready until all of these are true:

- HTTPS URL resolves;
- HEAD returns 200;
- Range request returns 206;
- Content-Range is present;
- PMTiles archive verifies;
- SHA-256 matches the catalog;
- attribution is exposed in the application;
- Android renders the online map;
- an approved region downloads and verifies;
- airplane mode renders from the verified local package;
- production never bulk-downloads from `tile.openstreetmap.org`.

Reference documentation:
- Cloudflare R2: https://developers.cloudflare.com/r2/
- Protomaps PMTiles cloud storage: https://docs.protomaps.com/pmtiles/cloud-storage
- Protomaps PMTiles CLI: https://docs.protomaps.com/pmtiles/cli
- OpenStreetMap copyright: https://www.openstreetmap.org/copyright
