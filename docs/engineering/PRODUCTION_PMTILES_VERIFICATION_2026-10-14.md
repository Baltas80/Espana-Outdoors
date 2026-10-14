# Production PMTiles verification evidence — 2026-10-14

## Result

**PASS — public Spain PMTiles object matches the live catalog metadata.**

This record captures the output provided by the operator after running the repository verifier and the HTTP range probe from Windows PowerShell. It records observed results; it does not claim the Android offline smoke test has passed.

## Full-object integrity

- Catalog URL: `https://maps.espanaoutdoor.es/catalog/spain.json`
- Map ID: `spain`
- Verifier result: `public_pmtiles_integrity=PASS`
- Exact downloaded size: `1269114296` bytes
- SHA-256: `f410f9961397ed502876a1843844a00b4fcf77f7d037c4ed12d716190ad73d4d`

The verifier compared the downloaded object's byte count and SHA-256 with the values declared in the live catalog.

## HTTP range support

Probe: request `Range: bytes=0-1023` against the catalog's `downloadUrl`.

Observed response:

- HTTP status: `206 Partial Content`
- `Content-Length: 1024`
- `Content-Range: bytes 0-1023/1269114296`
- `Accept-Ranges: bytes`
- `Content-Type: application/vnd.pmtiles`
- `Cache-Control: public, max-age=31536000, immutable`
- Server: `cloudflare`
- Observation time from response header: `Wed, 14 Oct 2026 17:52:04 GMT`

These headers confirm that the endpoint served the requested byte range and reported the total object size consistently with the full-object verification.

## Scope and remaining work

This closes the **public catalog/object integrity and HTTP range** verification gate.

It does **not** close:
- Android installation/download validation;
- interrupted/resumed download testing on the device;
- offline map rendering and navigation on a physical Android device;
- any separate dynamic weather/safety-data freshness checks.

No Cloudflare provisioning, object publication, or changes to `master` were performed for this verification record.
