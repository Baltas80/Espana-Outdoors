# Production PMTiles storage — Cloudflare R2

Cloudflare R2 is the selected first implementation for España Outdoor PMTiles storage.

## Why this path

- S3-compatible API for automated publication.
- Custom domain support for production.
- Public objects can be delivered read-only through a domain controlled by España Outdoor.
- Cloudflare documents HTTP range-request behavior for cached objects.
- CORS can be configured when a browser-based client requires it.
- R2's managed `r2.dev` endpoint is explicitly intended for development, not production.

Sources:
- https://developers.cloudflare.com/r2/buckets/public-buckets/
- https://developers.cloudflare.com/cache/reference/range-requests/
- https://developers.cloudflare.com/r2/buckets/cors/

## Required production resources

Create:

1. R2 bucket: `espana-outdoor-maps` (or the final approved name).
2. A custom domain controlled by España Outdoor, e.g. `maps.<owned-domain>`.
3. Public read access only for the immutable PMTiles objects.
4. CORS policy appropriate to the mobile/web client if needed.
5. Data Access Logs enabled.
6. Cache policy suitable for immutable versioned objects.

Do not use `r2.dev` for production.

## Object layout

```
/basemap/spain/<version>/spain.pmtiles
/basemap/spain/<version>/spain.pmtiles.sha256
/catalog/spain.json
```

Never overwrite a versioned PMTiles object.

## Credentials

The mobile application gets only a public HTTPS read URL. R2 S3 credentials stay in CI/deployment secrets.

Recommended CI secrets:

- `R2_ACCOUNT_ID`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`

Recommended repository/environment variables:

- `R2_BUCKET`
- `MAPS_PUBLIC_BASE_URL`

The final `MAP_PMTILES_URL` is derived from the approved custom domain and immutable object path; it is not invented in source code.
