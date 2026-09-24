# PMTiles R2 production runbook

## Objective
Publish the first real `spain.pmtiles` package through controlled HTTPS storage with HTTP Range support.

## Production gate

Do not set `MAP_PMTILES_URL` to a placeholder. The release environment must provide a real HTTPS URL only after all checks below pass.

## Build source

- Source: Geofabrik Spain OSM PBF or another explicitly approved OSM extract.
- Record source URL, retrieval timestamp and SHA-256.
- Preserve ODbL attribution and required notices.
- Generate `spain.pmtiles` with a reproducible build record.

## R2 publication

1. Create the production R2 bucket.
2. Upload `spain.pmtiles` as an immutable release object.
3. Put a controlled HTTPS custom domain/CDN in front of the object.
4. Ensure byte-range requests are supported and forwarded.
5. Verify `Accept-Ranges: bytes` where applicable.
6. Verify a range request returns HTTP `206 Partial Content` with a correct `Content-Range`.
7. Record object size and SHA-256.
8. Record the final stable HTTPS URL.

## Application configuration

Configure only the release environment:

- `MAP_PMTILES_URL=<verified production HTTPS URL>`
- `MAP_ATTRIBUTION=<verified OSM attribution>`

Never put provider credentials in the mobile binary.

## Offline validation

- Download a representative regional package through the application catalog.
- Verify checksum before accepting the package.
- Disable connectivity.
- Open the downloaded region and pan/zoom across its bounds.
- Confirm no fallback to public OSM raster tile servers occurs during offline use.

## Evidence required before marking production-ready

- R2 bucket/domain exists.
- Stable HTTPS URL returns the PMTiles object.
- Range request returns `206`.
- `spain.pmtiles` checksum is recorded.
- Attribution is present in the application.
- Online Android smoke test passes.
- Regional offline download passes.
- Offline map passes with network disabled.
- Release configuration contains no placeholder endpoint.

## Current state

**BLOCKED on external R2 account/bucket/domain provisioning.** The repository deliberately does not invent a production URL or credentials.
