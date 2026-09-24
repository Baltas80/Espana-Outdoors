# Production PMTiles provider path

## Decision

Use the mature **Protomaps Basemap + PMTiles CLI + object storage** path rather than bulk-prefetching a public OSM tile server.

The Protomaps Basemap is distributed as a single PMTiles archive derived from OpenStreetMap and is published under the Open Database License (ODbL), with OpenStreetMap attribution required. Protomaps explicitly recommends copying the archive to your own cloud storage rather than hotlinking the public download.

## Production flow

```text
Protomaps daily basemap
        |
        v
pmtiles extract (Spain / required regions)
        |
        +--> pmtiles verify
        |
        +--> SHA-256 checksum for España Outdoor catalogue
        |
        v
Cloudflare R2 / S3-compatible object storage
        |
        v
HTTPS + Range Requests + CDN/reverse proxy
        |
        v
MAP_PMTILES_URL / offline-region catalogue
```

The existing Flutter boundary remains unchanged: `MapService` owns map behavior, the PMTiles implementation owns archive access, and provider details stay outside the domain/UI layer.

## Region generation

The `pmtiles` CLI supports extracting a bounding box or GeoJSON region from a clustered source archive. For España Outdoor, generate regional archives instead of shipping the full planet archive to every user.

Example shape of the command (replace the source build and region file with the approved release inputs):

```bash
pmtiles extract SOURCE.pmtiles spain.pmtiles --region=spain.geojson
pmtiles verify spain.pmtiles
sha256sum spain.pmtiles > spain.pmtiles.sha256
```

Keep the source build date, source URL, ODbL attribution text, extraction geometry, PMTiles version and SHA-256 digest in the release record.

## Storage

Cloudflare R2 is the preferred first implementation because Protomaps documents it as a suitable PMTiles storage platform with HTTP Range support and no bandwidth fees. Any S3-compatible provider is acceptable if it supports:

- HTTP Range requests;
- stable HTTPS URLs;
- correct `Content-Range` / `Accept-Ranges` behavior;
- controlled CORS where required;
- object integrity/versioning;
- CDN or equivalent caching;
- operational access logging.

Do not commit storage credentials to Git.

## MapLibre contract

The application should ultimately receive a real value such as:

```text
MAP_PMTILES_URL=https://maps.espana-outdoor.example/regions/spain.pmtiles
```

The hostname above is intentionally illustrative and must not be used as a real endpoint.

Production is considered ready only after a real archive is uploaded, verified, served over HTTPS with Range support, and consumed successfully by the Android and iOS builds.

## Licensing

Before release, retain the provider/data licence record and required OpenStreetMap attribution with the production documentation. Do not assume that a public tile endpoint grants rights for bulk offline redistribution.
