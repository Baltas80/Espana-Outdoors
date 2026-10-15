# PMTiles offline verification status

**Updated:** 2026-10-15  
**Scope:** repository-side fixes and evidence supplied by the live-service audit.

## Verified by the supplied live audit

The audit reported the following results for the public catalogue and PMTiles object:

- The catalogue at `https://maps.espanaoutdoor.es/catalog/spain.json` returned HTTP 200 and valid JSON.
- The Spain archive was reported as 1,269,114,296 bytes, matching the catalogue size.
- HEAD returned HTTP 200 with a matching Content-Length.
- A valid range request returned HTTP 206 and the expected Content-Range/body length on the custom domain.
- The final byte was readable with HTTP 206.
- An out-of-bounds range returned HTTP 416 on the custom domain, but HTTP 500 on the `workers.dev` endpoint.
- The audit read PMTiles v3 header/metadata using ranges. It did **not** download the full archive to calculate its SHA-256.

These are observations from the audit report, not an independent re-run by this repository change.

## Repository changes in this branch

- The loopback PMTiles server distinguishes full, partial and unsatisfiable range requests.
- Out-of-bounds valid ranges return HTTP 416 and `Content-Range: bytes */N`.
- Malformed or unsupported multi-range requests are ignored rather than silently treated as a different partial request.
- Tests cover valid ranges, 416, malformed ranges, multi-range, suffix ranges and HEAD.
- Legacy local map records without a stored file fingerprint are hashed before a fingerprint is persisted.
- Offline package verifier tests cover checksum mismatch, size mismatch and missing required checksums.
- Catalog tests cover HTTP errors, malformed JSON, missing metadata and malformed download URLs.
- The public SHA-256 verification script rejects `workers.dev` download URLs.
- Dependabot tracks the two Go services in addition to Pub and GitHub Actions.

## External actions still required

1. Update the **published catalogue** so `downloadUrl` uses the audited custom-domain URL:
   `https://maps.espanaoutdoor.es/basemap/spain/2026-09-28/spain.pmtiles`
   This branch does not have credentials or a deployment mechanism for the live catalogue, so it does not change that external object.
2. The Cloudflare Worker source is not present in the repository. Do not invent or claim an audited Worker fix. If the Worker remains in use, export its actual source into `ops/workers/` and test its range behavior; otherwise keep it out of the mobile catalogue path.
3. Run the complete SHA-256 verification script against the published catalogue. The full 1.2 GB hash was not computed by the supplied audit.
4. Run `flutter analyze`, focused tests and the Android build in a Flutter-enabled CI environment.
5. On a physical Android device, download a region, close/reopen the app, enable airplane mode, pan/zoom and inspect logs for remote tile requests.

## Acceptance status

- [x] Repository code and test coverage changes prepared in this branch.
- [x] Production verification script rejects `workers.dev` map URLs.
- [ ] CI / Flutter tests pass on this branch.
- [ ] Published catalogue changed to the custom domain.
- [ ] Full archive SHA-256 verified against the published catalogue.
- [ ] Physical Android offline validation passes.

A green unit-test workflow is not a substitute for full-file integrity verification or physical offline validation.
