# PMTiles R2 production runbook

## Objective

Publish the reviewed spain.pmtiles package through a controlled HTTPS domain on Cloudflare R2. Production is not ready until the custom domain has active TLS and the published object passes HEAD and byte-range checks.

## Architecture

- Cloudflare R2 bucket stores public, read-only map packages and the offline catalog. A custom domain makes the bucket's objects publicly readable: use a dedicated map-only bucket and never reuse a bucket that contains private or unrelated objects.
- A custom HTTPS domain in the same Cloudflare account exposes the bucket through Cloudflare's R2 custom-domain service.
- Upload credentials remain server-side in GitHub Actions. No provider credentials are shipped in the mobile binary.
- The r2.dev development endpoint is not enabled by the provisioning script.
- Use immutable object keys for each map build; only update application release configuration after validating the new object.

## Required Cloudflare setup

Before provisioning, the domain must already exist as an active zone in the same Cloudflare account as R2. Choose a subdomain controlled by the project, for example maps.<owned-domain>. Do not substitute workers.dev, a third-party demo host, or a domain that the project does not control.

In GitHub repository Settings → Environments, create maps-production and configure:

### Environment secrets

- CLOUDFLARE_API_TOKEN: Cloudflare API token scoped to the target account with **Workers R2 Storage Write**. Do not use a global API key.
- R2_ACCOUNT_ID: target Cloudflare account ID (32 hex characters).

### Environment variables

- CLOUDFLARE_ZONE_ID: zone ID for the domain's zone in that same account.
- R2_BUCKET: production bucket name, e.g. espana-outdoor-maps-prod (3–63 lowercase letters, digits and interior hyphens).
- MAPS_PUBLIC_BASE_URL: HTTPS origin only, e.g. https://maps.<owned-domain>; no path, query string, port or trailing object name.
- R2_LOCATION_HINT: optional; defaults to weur. This is a placement hint, not a data-residency guarantee.

The provisioning token is only for managing the bucket and its custom domain. S3-compatible object-upload credentials (R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY) must be generated separately and scoped to the production bucket for the later upload workflow. Do not reuse or expose the provisioning token as an S3 secret.

## Provision bucket and HTTPS domain

After the workflow changes have landed on master:

1. Open GitHub Actions → **Provision PMTiles R2 storage**.
2. Run workflow on master, explicitly checking confirm_provision.
3. The workflow uses the protected maps-production environment and calls ops/offline/provision-r2-storage.sh.
4. The script is idempotent: it creates the bucket only if missing, attaches/enables the requested custom domain, sets minimum TLS to 1.2, and waits for Cloudflare domain ownership and TLS states to become active. The workflow requires two confirmations, including an explicit acknowledgement that all objects in the selected bucket may be public. It never deletes a bucket or removes existing objects.
5. Save the successful Actions run URL as provisioning evidence.

The script intentionally fails closed if identifiers are invalid, the API token lacks access, the domain cannot be attached, or ownership/TLS does not become active. Do not bypass these checks.

## Build source and publication (remaining gate)

- Source: Geofabrik Spain OSM PBF or another explicitly approved OSM extract.
- Record source URL, retrieval timestamp and source SHA-256.
- Preserve ODbL attribution and required notices.
- Generate spain.pmtiles with a reproducible, pinned Planetiler build.
- Upload as an immutable object (prefer a build/versioned key); record output SHA-256 and exact byte size.
- Publish the catalog entry with HTTPS URL, licence URL, attribution, size, timestamp and SHA-256.
- Configure production MAP_PMTILES_URL and OFFLINE_CATALOG_URL only to verified real HTTPS endpoints.
- Never use the public OSM raster tile service for production bulk/offline package delivery.

## HTTP and app validation

Run the existing repository gates against the final object and catalog:

- ops/offline/verify-pmtiles-http.sh: URL uses HTTPS, HEAD returns 200, and Range: bytes=0-1023 returns 206 plus Content-Range.
- ops/offline/verify-map-catalog.sh: catalog schema, metadata, SHA format, HTTPS URL and remote object size are valid.
- Test a production Android build on-device: online map render, offline region download with checksum validation, then airplane-mode map rendering.

For the HTTP check, use the final object URL, e.g. https://<maps-domain>/spain.pmtiles, only after the object has been uploaded. A domain with an empty bucket is provisioned infrastructure, not a published map.

## Evidence required before marking production-ready

- Successful provisioning workflow run and active ownership/TLS state.
- spain.pmtiles source provenance, immutable object key, SHA-256 and size.
- Stable HTTPS object URL returns 200 to HEAD.
- Byte-range request returns 206 and a valid Content-Range.
- Catalog has verified licence, attribution, timestamp, size and SHA-256.
- Online Android map renders; regional offline download verifies the checksum; airplane-mode rendering works.
- No placeholder endpoints or credentials in the release configuration or app binary.

## Current state

The repository now contains a guarded provisioning workflow and idempotent provisioning script. **Actual provisioning still requires the project owner's Cloudflare account, a domain zone in that account, and the maps-production secrets/variables above.** Provisioning the storage endpoint does not itself build or upload the Spain PMTiles package; publication and mobile verification remain separate gates.
